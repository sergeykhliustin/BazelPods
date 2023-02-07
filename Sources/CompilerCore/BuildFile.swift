//
//  Pod.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/14/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation

public struct PodBuildFile: StarlarkConvertible {
    /// Starlark Convertibles excluding prefix nodes.
    /// @note Use toStarlark() to generate the actual BUILD file
    let starlarkConvertibles: [StarlarkConvertible]

    private let options: BuildOptions

    /// Return the starlark representation of the entire BUILD file
    func toStarlark() -> StarlarkNode {
        let convertibleNodes: [StarlarkNode] = starlarkConvertibles.compactMap { $0.toStarlark() }

        return .lines([
            makeLoadNodes(forConvertibles: starlarkConvertibles)
        ] + [
            ConfigSetting.makeConfigSettingNodes()
        ] + convertibleNodes)
    }

    public static func with(podSpec: PodSpec,
                            buildOptions: BuildOptions =
                            BasicBuildOptions.empty) -> PodBuildFile {
        let libs = PodBuildFile.makeConvertables(fromPodspec: podSpec, buildOptions: buildOptions)
        return PodBuildFile(starlarkConvertibles: libs,
                            options: buildOptions)
    }

    func makeLoadNodes(forConvertibles starlarkConvertibles: [StarlarkConvertible]) -> StarlarkNode {
        return .lines(
            Set(
                starlarkConvertibles
                    .compactMap({ $0 as? BazelTarget })
                    .map({ $0.loadNode })
                    .filter({ !$0.isEmpty })
            )
            .sorted(by: <)
            .map({ StarlarkNode.starlark($0) })
        )
    }

    static func makeSourceLibs(info: BaseInfoAnalyzerResult,
                               sources: SourcesAnalyzerResult,
                               resources: ResourcesAnalyzer.Result,
                               sdkDeps: SdkDependenciesAnalyzer.Result,
                               vendoredDeps: VendoredDependenciesAnalyzer.Result,
                               spec: PodSpec,
                               subspecs: [PodSpec] = [],
                               deps: [BazelTarget] = [],
                               conditionalDeps: [String: [Arch]] = [:],
                               options: BuildOptions) -> ([BazelTarget], [InfoPlist]) {
        var targets: [BazelTarget] = []
        var infoplists: [InfoPlist] = []
        if sources.linkDynamic {
            let ruleName = "\(info.name)_InfoPlist"
            infoplists.append(InfoPlist(name: ruleName, framework: info))
        }
        let framework = AppleFramework(name: info.name,
                                       info: info,
                                       sources: sources,
                                       resources: resources,
                                       sdkDepsInfo: sdkDeps,
                                       vendoredDeps: vendoredDeps,
                                       infoplists: infoplists.map({ $0.name }),
                                       spec: spec,
                                       subspecs: subspecs,
                                       deps: Set((deps).map({ $0.name })),
                                       conditionalDeps: conditionalDeps,
                                       options: options)
        targets.append(framework)
        return (targets, infoplists)
    }

    static func makeResourceBundles(info: BaseInfoAnalyzerResult,
                                    resources: ResourcesAnalyzer.Result) -> (targets: [BazelTarget], infoplists: [InfoPlist]) {
        var targets: [BazelTarget] = []
        var infoplists: [InfoPlist] = []
        for bundle in resources.resourceBundles {
            let bundleRuleName = "\(info.moduleName)_\(bundle.name)_Bundle"
            let infoPlistRuleName = "\(bundleRuleName)_InfoPlist"
            targets.append(AppleResourceBundle(name: bundleRuleName, bundle: bundle, infoplists: [infoPlistRuleName]))
            infoplists.append(InfoPlist(name: infoPlistRuleName, resourceBundle: bundle.name, info: info))
        }
        return (targets, infoplists)
    }

    static func makeVendoredTargets(info: BaseInfoAnalyzerResult,
                                    vendored: VendoredDependenciesAnalyzer.Result) -> (targets: [BazelTarget], conditions: [String: [Arch]]) {
        var result = vendored.libraries.reduce(([BazelTarget](), [String: [Arch]]())) { partialResult, library in
            var targets = partialResult.0
            var conditions = partialResult.1
            let name = "\(info.moduleName)_\(library.name)_VendoredLibrary"
            conditions[name] = library.archs
            targets.append(ObjcImport(name: name, library: library.path))
            return (targets, conditions)
        }
        result = vendored.frameworks.reduce(result, { partialResult, framework in
            var targets = partialResult.0
            var conditions = partialResult.1
            let name = "\(info.moduleName)_\(framework.name)_VendoredFramework"
            conditions[name] = framework.archs
            targets.append(AppleFrameworkImport(name: name, isDynamic: framework.dynamic, isXCFramework: false, frameworkImport: framework.path))
            return (targets, conditions)
        })
        result = vendored.xcFrameworks.reduce(result, { partialResult, xcFramework in
            var targets = partialResult.0
            var conditions = partialResult.1
            let name = "\(info.moduleName)_\(xcFramework.name)_VendoredXCFramework"
            conditions[name] = xcFramework.archs
            targets.append(AppleFrameworkImport(name: name, isDynamic: xcFramework.dynamic, isXCFramework: true, frameworkImport: xcFramework.path))
            return (targets, conditions)
        })
        return result
    }

    static func makeConvertables(fromPodspec podSpec: PodSpec,
                                 buildOptions: BuildOptions = BasicBuildOptions.empty) -> [StarlarkConvertible] {
        let subspecs = podSpec.selectedSubspecs(subspecs: buildOptions.subspecs)
        // TODO: Platforms support
        let platform = Platform.ios
        let baseInfo = BaseInfoAnalyzer(platform: platform,
                                        spec: podSpec,
                                        subspecs: subspecs,
                                        options: buildOptions).result
        let sourcesInfo = SourcesAnalyzer(platform: platform,
                                          spec: podSpec,
                                          subspecs: subspecs,
                                          options: buildOptions).result
        let resourcesInfo = ResourcesAnalyzer(platform: platform,
                                              spec: podSpec,
                                              subspecs: subspecs,
                                              options: buildOptions).result
        let sdkDepsInfo = SdkDependenciesAnalyzer(platform: platform,
                                                  spec: podSpec,
                                                  subspecs: subspecs,
                                                  options: buildOptions).result
        let vendoredDepsInfo = VendoredDependenciesAnalyzer(platform: platform,
                                                            spec: podSpec,
                                                            subspecs: subspecs,
                                                            options: buildOptions).result

        let (resourceTargets, resourceInfoplists) = makeResourceBundles(info: baseInfo, resources: resourcesInfo)
        let (vendoredTargets, conditions) = makeVendoredTargets(info: baseInfo, vendored: vendoredDepsInfo)

        let (sourceTargets, infoplists) = makeSourceLibs(info: baseInfo,
                                                         sources: sourcesInfo,
                                                         resources: resourcesInfo,
                                                         sdkDeps: sdkDepsInfo,
                                                         vendoredDeps: vendoredDepsInfo,
                                                         spec: podSpec,
                                                         subspecs: subspecs,
                                                         deps: resourceTargets,
                                                         conditionalDeps: conditions,
                                                         options: buildOptions)
        var output: [BazelTarget] = []
        output += sourceTargets
        output += resourceTargets
        output += vendoredTargets
        output += infoplists
        output += resourceInfoplists

        output = UserConfigurableTransform.transform(convertibles: output,
                                                     options: buildOptions,
                                                     podSpec: podSpec)
        return output
    }

    public func compile() -> String {
        return StarlarkCompiler(toStarlark()).run()
    }
}

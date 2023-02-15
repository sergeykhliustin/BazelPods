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
    let archs: [Arch]

    private let options: BuildOptions

    /// Return the starlark representation of the entire BUILD file
    func toStarlark() -> StarlarkNode {
        let convertibleNodes: [StarlarkNode] = starlarkConvertibles.compactMap { $0.toStarlark() }

        return .lines([
            makeLoadNodes(forConvertibles: starlarkConvertibles)
        ] + [
            ConfigSetting.makeConfigSettingNodes(archs: archs)
        ] + convertibleNodes)
    }

    public static func with(podSpec: PodSpec,
                            buildOptions: BuildOptions) -> PodBuildFile {
        let (convertables, archs) = PodBuildFile.makeConvertablesAndArchs(fromPodspec: podSpec, options: buildOptions)
        return PodBuildFile(starlarkConvertibles: convertables,
                            archs: archs,
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

    static func makeSourceLibs(analyzer: Analyzer,
                               deps: [String],
                               conditionalDeps: [String: [Arch]])
    -> ([BazelTarget], [InfoPlist]) {
        let info = analyzer.baseInfo
        var targets: [BazelTarget] = []
        var infoplists: [InfoPlist] = []

        var infoplistRuleName: String?
        if analyzer.sourcesInfo.linkDynamic {
            let ruleName = analyzer.targetName.baseInfoplist(info.name)
            infoplists.append(InfoPlist(name: ruleName, framework: info))
            infoplistRuleName = ruleName
        }

        let framework = AppleFramework(name: analyzer.targetName.base(info.name),
                                       info: info,
                                       sources: analyzer.sourcesInfo,
                                       resources: analyzer.resourcesInfo,
                                       sdkDeps: analyzer.sdkDepsInfo,
                                       vendoredDeps: analyzer.vendoredDepsInfo,
                                       buildSettings: analyzer.buildSettingsInfo,
                                       infoplists: [infoplistRuleName].compactMap({ $0 }),
                                       deps: deps,
                                       conditionalDeps: conditionalDeps)
        targets.append(framework)

        return (targets, infoplists)
    }

    static func makeResourceBundles(analyzer: Analyzer) -> (targets: [BazelTarget], infoplists: [InfoPlist]) {
        var targets: [BazelTarget] = []
        var infoplists: [InfoPlist] = []
        for bundle in analyzer.resourcesInfo.resourceBundles {
            let bundleRuleName = analyzer.targetName.bundle(analyzer.baseInfo.moduleName, bundle: bundle.name)
            let infoPlistRuleName = analyzer.targetName.bundleInfoplist(analyzer.baseInfo.moduleName, bundle: bundle.name)
            targets.append(AppleResourceBundle(name: bundleRuleName, bundle: bundle, infoplists: [infoPlistRuleName]))
            infoplists.append(InfoPlist(name: infoPlistRuleName, resourceBundle: bundle.name, info: analyzer.baseInfo))
        }
        return (targets, infoplists)
    }

    static func makeVendoredTargets(analyzer: Analyzer)
    -> (targets: [BazelTarget], conditions: [String: [Arch]]) {
        let baseInfo = analyzer.baseInfo
        let vendored = analyzer.vendoredDepsInfo

        var result = vendored.libraries.reduce(([BazelTarget](), [String: [Arch]]())) { partialResult, library in
            var targets = partialResult.0
            var conditions = partialResult.1
            let name = analyzer.targetName.library(baseInfo.moduleName, library: library.name)
            conditions[name] = library.archs
            targets.append(ObjcImport(name: name, library: library.path))
            return (targets, conditions)
        }
        result = vendored.frameworks.reduce(result, { partialResult, framework in
            var targets = partialResult.0
            var conditions = partialResult.1
            let name = analyzer.targetName.framework(baseInfo.moduleName, framework: framework.name)
            conditions[name] = framework.archs
            targets.append(AppleFrameworkImport(name: name, isDynamic: framework.dynamic, isXCFramework: false, frameworkImport: framework.path))
            return (targets, conditions)
        })
        result = vendored.xcFrameworks.reduce(result, { partialResult, xcFramework in
            var targets = partialResult.0
            var conditions = partialResult.1
            let name = analyzer.targetName.xcframework(baseInfo.moduleName, xcframework: xcFramework.name)
            conditions[name] = xcFramework.archs
            targets.append(AppleFrameworkImport(name: name, isDynamic: xcFramework.dynamic, isXCFramework: true, frameworkImport: xcFramework.path))
            return (targets, conditions)
        })
        return result
    }

    static func makeConvertablesAndArchs(fromPodspec spec: PodSpec,
                                         options: BuildOptions)
    -> ([StarlarkConvertible], [Arch]) {
        let subspecs = spec.selectedSubspecs(subspecs: options.subspecs)
        // TODO: Platforms support
        let platform = Platform.ios
        var analyzer = Analyzer(platform: platform,
                                spec: spec,
                                subspecs: subspecs,
                                options: options)
        analyzer.patch(BundlesDeduplicate())

        let (resourceTargets, resourceInfoplists) = makeResourceBundles(analyzer: analyzer)
        let (vendoredTargets, conditions) = makeVendoredTargets(analyzer: analyzer)

        let deps = (
            (resourceTargets.map({ $0.name })) +
            analyzer.podDependencies
        ).sorted()

        let (sourceTargets, infoplists) = makeSourceLibs(analyzer: analyzer,
                                                         deps: deps,
                                                         conditionalDeps: conditions)
        let archs = conditions.reduce(Set<Arch>()) { partialResult, element in
            var result = partialResult
            element.value.forEach({
                result.insert($0)
            })
            return result
        }.sorted()

        var output: [BazelTarget] = []
        output += sourceTargets
        output += resourceTargets
        output += vendoredTargets
        output += infoplists
        output += resourceInfoplists

        output = UserConfigurableTransform.transform(convertibles: output,
                                                     options: options,
                                                     podSpec: spec)
        return (output, archs)
    }

    public func compile() -> String {
        return StarlarkCompiler(toStarlark()).run()
    }
}

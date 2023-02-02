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

    static func makeSourceLibs(spec: PodSpec,
                               subspecs: [PodSpec] = [],
                               deps: [BazelTarget] = [],
                               conditionalDeps: [String: [Arch]] = [:],
                               dataDeps: [BazelTarget] = [],
                               options: BuildOptions) -> [BazelTarget] {
        var result: [BazelTarget] = []
        var framework = AppleFramework(spec: spec,
                                       subspecs: subspecs,
                                       deps: Set((deps + dataDeps).map({ $0.name })),
                                       conditionalDeps: conditionalDeps,
                                       options: options)
        if framework.needsInfoPlist {
            let infoplist = InfoPlist(framework: framework, spec: spec, options: options)
            framework.addInfoPlist(infoplist)
            result.append(infoplist)
        }
        result.append(framework)

        return result
    }

    static func makeResourceBundles(spec: PodSpec,
                                    subspecs: [PodSpec] = [],
                                    options: BuildOptions) -> [BazelTarget] {
        var result: [BazelTarget] = []
        let bundles = AppleResourceBundle.bundleResources(withPodSpec: spec, subspecs: subspecs, options: options)
        for bundle in bundles {
            var bundle = bundle
            let infoplist = InfoPlist(bundle: bundle, spec: spec, options: options)
            bundle.addInfoPlist(infoplist)
            result.append(bundle)
            result.append(infoplist)
        }
        return result
    }

    static func makeConvertables(fromPodspec podSpec: PodSpec,
                                 buildOptions: BuildOptions = BasicBuildOptions.empty) -> [StarlarkConvertible] {
        let subspecs = podSpec.selectedSubspecs(subspecs: buildOptions.subspecs)

        let extraDeps: [BazelTarget] = makeResourceBundles(spec: podSpec, subspecs: subspecs, options: buildOptions)
        let frameworks = AppleFrameworkImport.vendoredFrameworks(withPodspec: podSpec, subspecs: subspecs, options: buildOptions)
        let libraries = ObjcImport.vendoredLibraries(withPodspec: podSpec, subspecs: subspecs, options: buildOptions)
        let conditionalDeps = (frameworks + libraries).reduce([String: [Arch]]()) { partialResult, target in
            if let target = target as? AppleFrameworkImport {
                var result = partialResult
                let path = frameworkExecutablePath(target.frameworkImport, options: buildOptions)
                result[target.name] = Arch.archs(forExecutable: path, options: buildOptions)
                return result
            } else if let target = target as? ObjcImport {
                var result = partialResult
                let path = URL(fileURLWithPath: target.library, relativeTo: URL(fileURLWithPath: buildOptions.podTargetAbsoluteRoot)).path
                result[target.name] = Arch.archs(forExecutable: path, options: buildOptions)
                return result
            }
            return partialResult
        }

        let sourceLibs = makeSourceLibs(spec: podSpec,
                                        subspecs: subspecs,
                                        deps: extraDeps.filter({ !($0 is InfoPlist) }),
                                        conditionalDeps: conditionalDeps,
                                        options: buildOptions)

        var output: [BazelTarget] = sourceLibs + extraDeps + frameworks + libraries

        output = UserConfigurableTransform.transform(convertibles: output,
                                                     options: buildOptions,
                                                     podSpec: podSpec)
        return output
    }

    public func compile() -> String {
        return StarlarkCompiler(toStarlark()).run()
    }
}

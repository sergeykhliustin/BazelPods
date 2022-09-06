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
                .map({ StarlarkNode.starlark($0) })
        )
    }

    static func makeSourceLibs(spec: PodSpec,
                               subspecs: [PodSpec] = [],
                               deps: [BazelTarget] = [],
                               dataDeps: [BazelTarget] = [],
                               options: BuildOptions) -> [BazelTarget] {
        var result: [BazelTarget] = []
        var framework = AppleFramework(spec: spec,
                                       subspecs: subspecs,
                                       deps: Set((deps + dataDeps).map({ $0.name })),
                                       options: options)
        if options.linkDynamic && framework.canLinkDynamic {
            let infoplist = InfoPlist(framework: framework, spec: spec, options: options)
            framework.addInfoPlist(infoplist)
            result.append(infoplist)
        }
        result.append(framework)

        return result
    }

    static func makeConvertables(
            fromPodspec podSpec: PodSpec,
            buildOptions: BuildOptions = BasicBuildOptions.empty
    ) -> [StarlarkConvertible] {
        let subspecs = podSpec.selectedSubspecs(subspecs: buildOptions.subspecs)

        let extraDeps: [BazelTarget] = []

        let sourceLibs = makeSourceLibs(spec: podSpec,
                                        subspecs: subspecs,
                                        deps: extraDeps,
                                        options: buildOptions)

        var output: [BazelTarget] = sourceLibs + extraDeps

        output = UserConfigurableTransform.transform(convertibles: output,
                                                     options: buildOptions,
                                                     podSpec: podSpec)
        return output
    }

    public func compile() -> String {
        return StarlarkCompiler(toStarlark()).run()
    }
}

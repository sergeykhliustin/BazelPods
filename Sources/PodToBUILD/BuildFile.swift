//
//  Pod.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/14/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation

public struct PodBuildFile: SkylarkConvertible {
    /// Skylark Convertibles excluding prefix nodes.
    /// @note Use toSkylark() to generate the actual BUILD file
    let skylarkConvertibles: [SkylarkConvertible]

    private let options: BuildOptions

    /// Return the skylark representation of the entire BUILD file
    func toSkylark() -> SkylarkNode {
        let convertibleNodes: [SkylarkNode] = skylarkConvertibles.compactMap { $0.toSkylark() }

        return .lines([
            makeLoadNodes(forConvertibles: skylarkConvertibles)
        ] + [
            ConfigSetting.makeConfigSettingNodes()
        ] + convertibleNodes)
    }

    public static func with(podSpec: PodSpec,
                            buildOptions: BuildOptions =
                            BasicBuildOptions.empty) -> PodBuildFile {
        let libs = PodBuildFile.makeConvertables(fromPodspec: podSpec, buildOptions: buildOptions)
        return PodBuildFile(skylarkConvertibles: libs,
                            options: buildOptions)
    }

    func makeLoadNodes(forConvertibles skylarkConvertibles: [SkylarkConvertible]) -> SkylarkNode {
        return .lines(
            Set(
                skylarkConvertibles
                    .compactMap({ $0 as? BazelTarget })
                    .map({ $0.loadNode })
                    .filter({ !$0.isEmpty })
                )
                .map({ SkylarkNode.skylark($0) })
        )
    }

    static func makeSourceLibs(spec: PodSpec,
                               subspecs: [PodSpec] = [],
                               deps: [BazelTarget] = [],
                               dataDeps: [BazelTarget] = [],
                               options: BuildOptions) -> [BazelTarget] {
        return [
            AppleFramework(spec: spec,
                           subspecs: subspecs,
                           deps: Set((deps + dataDeps).map({ $0.name })),
                           options: options)
        ]
    }

    static func makeConvertables(
            fromPodspec podSpec: PodSpec,
            buildOptions: BuildOptions = BasicBuildOptions.empty
    ) -> [SkylarkConvertible] {
        let subspecs = podSpec.selectedSubspecs(subspecs: buildOptions.subspecs)

        let extraDeps =
            AppleFrameworkImport.vendoredFrameworks(withPodspec: podSpec, subspecs: subspecs, options: buildOptions) +
            ObjcImport.vendoredLibraries(withPodspec: podSpec, subspecs: subspecs)

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
        return SkylarkCompiler(toSkylark()).run()
    }
}

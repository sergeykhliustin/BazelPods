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

    public func compile() -> String {
        return StarlarkCompiler(toStarlark()).run()
    }
}

//
//  ConfigSetting.swift
//  BazelPods
//
//  Created by Sergey Khliustin on 27.08.2022.
//

import Foundation

// https://bazel.build/versions/master/docs/be/general.html#config_setting
public struct ConfigSetting: BazelTarget {
    public let loadNode = ""
    public let name: String
    let values: [String: String]

    public func toStarlark() -> StarlarkNode {
        return .functionCall(
            name: "config_setting",
            arguments: [
                .named(name: "name", value: name.toStarlark()),
                .named(name: "values", value: values.toStarlark())
            ])
    }

    /// Config Setting Nodes
    /// Write Build dependent COPTS.
    /// @note We consume this as an expression in ObjCLibrary
    static func makeConfigSettingNodes(archs: [Arch]) -> StarlarkNode {
        let comment = [
            "# Add a config setting release for compilation mode",
            "# Assume that people are using `opt` for release mode",
            "# see the bazel user manual for more information",
            "# https://docs.bazel.build/versions/master/be/general.html#config_setting"
        ].map { StarlarkNode.starlark($0) }
        var settings = [
            ConfigSetting(
                name: "release",
                values: ["compilation_mode": "opt"]).toStarlark()
        ]
        settings.append(contentsOf: archs.map({
            ConfigSetting(name: $0.rawValue, values: ["cpu": $0.rawValue]).toStarlark()
        }))

        return .lines([.lines(comment)] + settings)
    }
}

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

    public func toSkylark() -> SkylarkNode {
        return .functionCall(
            name: "config_setting",
            arguments: [
                .named(name: "name", value: name.toSkylark()),
                .named(name: "values", value: values.toSkylark())
            ])
    }

    /// Config Setting Nodes
    /// Write Build dependent COPTS.
    /// @note We consume this as an expression in ObjCLibrary
    static func makeConfigSettingNodes() -> SkylarkNode {
        let comment = [
            "# Add a config setting release for compilation mode",
            "# Assume that people are using `opt` for release mode",
            "# see the bazel user manual for more information",
            "# https://docs.bazel.build/versions/master/be/general.html#config_setting",
        ].map { SkylarkNode.skylark($0) }
        return .lines([.lines(comment),
            ConfigSetting(
                name: "release",
                values: ["compilation_mode": "opt"]).toSkylark(),
            ConfigSetting(
                name: "osxCase",
                values: ["apple_platform_type": "macos"]).toSkylark(),
            ConfigSetting(
                name: "tvosCase",
                values: ["apple_platform_type": "tvos"]).toSkylark(),
            ConfigSetting(
                name: "watchosCase",
                values: ["apple_platform_type": "watchos"]).toSkylark()
        ])
    }
}

//
//  iOSAppHost.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 27.02.2024.
//

import Foundation

struct iOSAppHost: BazelTarget {
    let loadNode = "load('@build_bazel_rules_apple//apple:ios.bzl', ios_application_native = 'ios_application')"
    let name: String
    let minimumOSVersion: String
    let infoPlist: String
    let resources: [String]
    let deps: [String]

    var bundleId: String {
        return "org.cocoapods.\(name.replacingOccurrences(of: "_", with: "-"))"
    }

    var families: [String] {
        return ["iphone"]
    }

    func toStarlark() -> StarlarkNode {
        let lines: [StarlarkFunctionArgument] = [
            .named(name: "name", value: name.toStarlark()),
            .named(name: "bundle_id", value: bundleId.toStarlark()),
            .named(name: "families", value: families.toStarlark()),
            .named(name: "minimum_os_version", value: minimumOSVersion.toStarlark()),
            .named(name: "infoplists", value: [":" + infoPlist].toStarlark()),
            .named(name: "resources", value: resources.map({ ":" + $0 }).toStarlark()),
            .named(name: "deps", value: deps.map({ ":" + $0 }).toStarlark())
        ]
        return .functionCall(
            name: "ios_application_native",
            arguments: lines
        )
    }
}

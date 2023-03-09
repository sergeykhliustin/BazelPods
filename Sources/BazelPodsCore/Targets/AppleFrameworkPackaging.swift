//
//  AppleFrameworkPackaging.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 13.02.2023.
//

import Foundation

struct AppleFrameworkPackaging: BazelTarget {
    let loadNode = "load('@build_bazel_rules_ios//rules:framework.bzl', 'apple_framework_packaging')"

    let name: String
    let info: BaseAnalyzer.Result
    let frameworkName: String
    let deps: [String]

    init(name: String,
         info: BaseAnalyzer.Result,
         frameworkName: String,
         deps: [String]) {
        self.name = name
        self.info = info
        self.frameworkName = frameworkName
        self.deps = deps
    }

    func toStarlark() -> StarlarkNode {
        let bundleId = "org.cocoapods.\(info.name)"
        let lines: [StarlarkFunctionArgument] = [
            .named(name: "name", value: name.toStarlark()),
            .named(name: "bundle_id", value: bundleId.toStarlark()),
            .named(name: "platforms", value: info.platforms.toStarlark()),
            .named(name: "link_dynamic", value: true.toStarlark()),
            .named(name: "infoplists", value: [String]().toStarlark()),
            .named(name: "framework_name", value: frameworkName.toStarlark()),
            .named(name: "deps", value: deps.map({ ":" + $0 }).toStarlark()),
            .named(name: "transitive_deps", value: [String]().toStarlark()),
            .named(name: "visibility", value: ["//visibility:public"].toStarlark())
        ]
        return .functionCall(name: "apple_framework_packaging",
                             arguments: lines)
    }
}

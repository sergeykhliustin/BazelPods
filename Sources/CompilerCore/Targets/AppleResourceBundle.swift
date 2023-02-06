//
//  AppleResourceBundle.swift
//  BazelPods
//
//  Created by Sergey Khliustin on 27.08.2022.
//

import Foundation

// https://github.com/bazel-ios/rules_ios/blob/master/rules/precompiled_apple_resource_bundle.bzl
// Using this rule since apple_framework.resource_bundles conflicts when bundle_name == apple_framework.name and dynamic linking
struct AppleResourceBundle: BazelTarget {
//    let loadNode = "load('@build_bazel_rules_apple//apple:resources.bzl', 'apple_resource_bundle')"
    let loadNode = "load('@build_bazel_rules_ios//rules:precompiled_apple_resource_bundle.bzl', 'precompiled_apple_resource_bundle')"
    let name: String
    let bundleId: String
    let bundleName: String
    let resources: [String]
    var infoplists: [String] = []

    init(name: String, bundle: ResourcesAnalyzer.Result.Bundle, infoplists: [String]) {
        self.name = name
        self.bundleName = bundle.name
        self.bundleId = "org.cocoapods.\(bundleName)"
        self.resources = bundle.resources
        self.infoplists = infoplists
    }

    func toStarlark() -> StarlarkNode {
        return .functionCall(
            name: "precompiled_apple_resource_bundle",
            arguments: [
                .named(name: "name", value: name.toStarlark()),
                .named(name: "bundle_id", value: bundleId.toStarlark()),
                .named(name: "bundle_name", value: bundleName.toStarlark()),
                .named(name: "infoplists", value: infoplists.map({ ":" + $0 }).toStarlark()),
                .named(name: "resources",
                       value: GlobNode(include: resources).toStarlark() )
        ])
    }
}

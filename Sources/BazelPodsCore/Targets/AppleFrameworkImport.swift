//
//  AppleFrameworkImport.swift
//  BazelPods
//
//  Created by Sergey Khliustin on 27.08.2022.
//

import Foundation

// https://github.com/bazelbuild/rules_apple/blob/818e795208ae3ca1cf1501205549d46e6bc88d73/doc/rules-general.md#apple_static_framework_import
struct AppleFrameworkImport: BazelTarget {
    var loadNode: String {
        let rule = appleFrameworkImport(isDynamic: isDynamic, isXCFramework: isXCFramework)
        return "load('@build_bazel_rules_apple//apple:apple.bzl', '\(rule)')"
    }
    let name: String // A unique name for this rule.
    // The list of files under a .framework directory which are provided to Objective-C targets that depend on this target.
    let frameworkImport: String
    let isXCFramework: Bool
    let isDynamic: Bool

    init(name: String, isDynamic: Bool, isXCFramework: Bool, frameworkImport: String) {
        self.name = name
        self.isDynamic = isDynamic
        self.frameworkImport = frameworkImport
        self.isXCFramework = isXCFramework
    }

    // apple_static_framework_import(
    //     name = "OCMock",
    //     framework_imports = [
    //         glob(["iOS/OCMock.framework/**"]),
    //     ],
    //     visibility = ["visibility:public"]
    // )
    func toStarlark() -> StarlarkNode {
        let ruleName = appleFrameworkImport(isDynamic: isDynamic, isXCFramework: isXCFramework)

        return StarlarkNode.functionCall(
            name: ruleName,
                arguments: [StarlarkFunctionArgument]([
                    .named(name: "name", value: .string(name)),
                    .named(name: isXCFramework ? "xcframework_imports": "framework_imports",
                           value: GlobNodeV2(include: [frameworkImport.appendingPath("/**")]).toStarlark()),
                    .named(name: "visibility", value: .list(["//visibility:public"]))
                ])
        )
    }

    /// framework import for apple framework import
    /// - Parameters:
    ///   - isDynamic: whether internal framework is dynamic or static
    ///   - isXCFramework: if it is XCFramework
    /// - Returns: apple framework import string such as "apple_static_xcframework_import"
    func appleFrameworkImport(isDynamic: Bool, isXCFramework: Bool) -> String {
        return "apple_" + (isDynamic ? "dynamic_" : "static_") + (isXCFramework ? "xcframework_" : "framework_") + "import"
    }
}

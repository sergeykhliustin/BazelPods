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
        if isXCFramework {
            return "load('@build_bazel_rules_apple//apple:apple.bzl', '\(rule)')"
        } else {
            return "load('@build_bazel_rules_ios//rules:apple_patched.bzl', '\(rule)')"
        }
    }
    let name: String // A unique name for this rule.
    let frameworkImport: AttrSet<String> // The list of files under a .framework directory which are provided to Objective-C targets that depend on this target.
    let isXCFramework: Bool
    let isDynamic: Bool

    init(name: String, isDynamic: Bool, isXCFramework: Bool, frameworkImport: AttrSet<String>) {
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
    func toSkylark() -> SkylarkNode {
        let ruleName = appleFrameworkImport(isDynamic: isDynamic, isXCFramework: isXCFramework)

        return SkylarkNode.functionCall(
            name: ruleName,
                arguments: [SkylarkFunctionArgument]([
                    .named(name: "name", value: .string(name)),
                    .named(name: isXCFramework ? "xcframework_imports": "framework_imports",
                           value: frameworkImport.map {
                                  GlobNode(include: Set([$0 + "/**"]))
                            }.toSkylark()),
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

    static func vendoredFrameworks(withPodspec spec: PodSpec, subspecs: [PodSpec], options: BuildOptions) -> [BazelTarget] {
        // TODO: Make frameworks AttrSet
        let vendoredFrameworks = spec.collectAttribute(with: subspecs, keyPath: \.vendoredFrameworks).map({ $0.filter({ !$0.hasSuffix("xcframework") }) })
        let frameworks = vendoredFrameworks.map {
            $0.compactMap {
                let isDynamic = isFrameworkDynamic($0, options: options)
                let frameworkName = URL(fileURLWithPath: $0).deletingLastPathComponent().lastPathComponent

                return AppleFrameworkImport(name: "\(spec.moduleName ?? spec.name)_\(frameworkName)_VendoredFramework",
                                            isDynamic: isDynamic,
                                            isXCFramework: false,
                                            frameworkImport: AttrSet(basic: $0))
            } as [AppleFrameworkImport]
        }
        return (frameworks.basic ?? []) + (frameworks.multi.ios ?? [])
    }
}

//
//  AppleBundleImport.swift
//  BazelPods
//
//  Created by Sergey Khliustin on 27.08.2022.
//

import Foundation
// Currently not used
// https://github.com/bazelbuild/rules_apple/blob/master/doc/rules-resources.md#apple_bundle_import
public struct AppleBundleImport: BazelTarget {
    public let loadNode = "load('@build_bazel_rules_apple//apple:resources.bzl', 'apple_bundle_import')"
    public let name: String
    let bundleImports: AttrSet<[String]>

    public var acknowledged: Bool {
        return true
    }

    public func toStarlark() -> StarlarkNode {
        return .functionCall(
            name: "apple_bundle_import",
            arguments: [
                .named(name: "name", value: name.toStarlark()),
                .named(name: "bundle_imports",
                       value: bundleImports.map { GlobNode(include: $0.sorted()) }.toStarlark() )
                ])
    }

    static func extractBundleName(fromPath path: String) -> String {
        return path.components(separatedBy: "/").map { (s: String) in
            s.hasSuffix(".bundle") ? s : ""
            }.reduce("", +).replacingOccurrences(of: ".bundle", with: "")
    }

}

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
    let resources: AttrSet<Set<String>>
    var infoplists: [String] = []

    func toStarlark() -> StarlarkNode {
        let resources = extractResources(patterns: (resources.basic ?? []).union(resources.multi.ios ?? []))

        return .functionCall(
            name: "precompiled_apple_resource_bundle",
            arguments: [
                .named(name: "name", value: name.toStarlark()),
                .named(name: "bundle_id", value: bundleId.toStarlark()),
                .named(name: "bundle_name", value: bundleName.toStarlark()),
                .named(name: "infoplists", value: infoplists.toStarlark()),
                .named(name: "resources",
                       value: GlobNode(include: resources).toStarlark() )
        ])
    }

    mutating func addInfoPlist(_ target: BazelTarget) {
        self.infoplists.append(":" + target.name)
    }

    static func bundleResources(withPodSpec spec: PodSpec, subspecs: [PodSpec], options: BuildOptions) -> [AppleResourceBundle] {
        // See if the Podspec specifies a prebuilt .bundle file

        let resourceBundles = spec.collectAttribute(with: subspecs, keyPath: \.resourceBundles)
            .map({ value -> [String: Set<String>] in
                var result = [String: Set<String>]()
                for key in value.keys {
                    result[key] = Set(extractResources(patterns: value[key]!))
                }
                return result
            })
            .map({
                return $0.map({ (x: (String, Set<String>)) -> AppleResourceBundle  in
                    let name = "\(spec.moduleName ?? spec.name)_\(x.0)_Bundle"
                    let bundleName = x.0
                    return AppleResourceBundle(name: name,
                                               bundleId: "org.cocoapods.\(bundleName)",
                                               bundleName: bundleName,
                                               resources: AttrSet(basic: x.1))
                })
            })

        return ((resourceBundles.basic ?? []) + (resourceBundles.multi.ios ??
        [])).sorted { $0.name < $1.name }
    }
}

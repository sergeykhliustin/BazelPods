//
//  AppleResourceBundle.swift
//  BazelPods
//
//  Created by Sergey Khliustin on 27.08.2022.
//

import Foundation

// Currently not used
// https://github.com/bazelbuild/rules_apple/blob/0.13.0/doc/rules-resources.md#apple_resource_bundle
struct AppleResourceBundle: BazelTarget {
    let loadNode = "load('@build_bazel_rules_apple//apple:resources.bzl', 'apple_resource_bundle')"
    let name: String
    let bundleName: String
    let resources: AttrSet<Set<String>>

    func toStarlark() -> StarlarkNode {
        let resources = extractResources(patterns: (resources.basic ?? []).union(resources.multi.ios ?? []))

        return .functionCall(
            name: "apple_resource_bundle",
            arguments: [
                .named(name: "name", value: name.toStarlark()),
                .named(name: "bundle_name", value: bundleName.toStarlark()),
                .named(name: "infoplists", value: ["\(name)_InfoPlist"].toStarlark()),
                .named(name: "resources",
                       value: GlobNode(include: resources).toStarlark() )
        ])
    }

    static func bundleResources(withPodSpec spec: PodSpec, subspecs: [PodSpec], options: BuildOptions) -> [BazelTarget] {
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
                    return AppleResourceBundle(name: name, bundleName: bundleName, resources: AttrSet(basic: x.1))
                })
            })

        return ((resourceBundles.basic ?? []) + (resourceBundles.multi.ios ??
        [])).sorted { $0.name < $1.name }
    }
}

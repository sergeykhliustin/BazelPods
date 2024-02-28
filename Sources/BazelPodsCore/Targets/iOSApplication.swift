//
//  iOSApplication.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 08.02.2024.
//

import Foundation

struct iOSApplication: BazelTarget {
    let loadNode = "load('@build_bazel_rules_ios//rules:app.bzl', 'ios_application')"
    let name: String
    let info: BaseAnalyzer<AppSpec>.Result
    let sources: SourcesAnalyzer<AppSpec>.Result
    let resources: ResourcesAnalyzer<AppSpec>.Result
    let deps: [String]
    let infoPlist: String
    let bundleId: String
    let conditionalDeps: [String: [Arch]]

    func toStarlark() -> StarlarkNode {
        let deps = makeDeps(deps: deps, conditionalDeps: conditionalDeps)

        let lines: [StarlarkFunctionArgument] = [
            .named(name: "name", value: name.toStarlark()),
            .named(name: "module_name", value: info.moduleName.toStarlark()),
            .named(name: "bundle_id", value: bundleId.toStarlark()),
            .named(name: "minimum_os_version", value: info.minimumOsVersion.toStarlark()),
            .named(name: "infoplists", value: [":" + infoPlist].toStarlark()),
            .named(name: "srcs", value: sources.sourceFiles.toStarlark()),
            .named(name: "data", value: resources.packedToDataNode),
            .named(name: "deps", value: deps.toStarlark()),
            .named(name: "visibility", value: ["//visibility:public"].toStarlark())
        ]
            .filter({
                switch $0 {
                case .basic:
                    return true
                case .named(_, let value):
                    return !value.isEmpty
                }
            })
        return .functionCall(
            name: "ios_application",
            arguments: lines
        )
    }
}

//
//  iOSUITest.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 02.02.2024.
//

import Foundation

struct iOSUITest: BazelTarget {
    let loadNode = "load('@build_bazel_rules_ios//rules:test.bzl', 'ios_ui_test')"
    let name: String
    let info: BaseAnalyzer<TestSpec>.Result
    let sources: SourcesAnalyzer<TestSpec>.Result
    let resources: ResourcesAnalyzer<TestSpec>.Result
    let deps: [String]
    let timeout: String
    let testHost: String?
    let infoPlist: String
    let environment: [String: String]
    let launchArguments: [String]
    let conditionalDeps: [String: [Arch]]
    let runner: String?

    func toStarlark() -> StarlarkNode {
        var test_host = ""
        if let testHost, !testHost.isEmpty {
            test_host = ":" + testHost
        }
        var runnerName = self.runner
        if let runner = self.runner, !runner.isEmpty, !runner.hasPrefix("/") {
            runnerName = ":" + runner
        }

        let deps = makeDeps(deps: deps, conditionalDeps: conditionalDeps)

        var args: [String] = []
        if !launchArguments.isEmpty {
            args = [
                "--command_line_args=\(launchArguments.joined(separator: ","))"
            ]
        }

        let lines: [StarlarkFunctionArgument] = [
            .named(name: "name", value: name.toStarlark()),
            .named(name: "module_name", value: info.moduleName.toStarlark()),
            .named(name: "minimum_os_version", value: info.minimumOsVersion.toStarlark()),
            .named(name: "test_host", value: test_host.toStarlark()),
            .named(name: "runner", value: (runnerName ?? "").toStarlark()),
            .named(name: "infoplists", value: [":" + infoPlist].toStarlark()),
            .named(name: "srcs", value: sources.sourceFiles.toStarlark()),
            .named(name: "data", value: resources.packedToDataNode),
            .named(name: "deps", value: deps.toStarlark()),
            .named(name: "args", value: args.toStarlark()),
            .named(name: "env", value: environment.toStarlark()),
            .named(name: "timeout", value: timeout.toStarlark()),
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
            name: "ios_ui_test",
            arguments: lines
        )
    }
}

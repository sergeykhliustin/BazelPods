//
//  iOSTestRunner.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 28.02.2024.
//

import Foundation

struct iOSXCTestrunRunner: BazelTarget {
    let loadNode = "load('@build_bazel_rules_apple//apple/testing/default_runner:ios_xctestrun_runner.bzl', 'ios_xctestrun_runner')"
    let name: String
    let commandLineArgs: [String]

    func toStarlark() -> StarlarkNode {
        let lines: [StarlarkFunctionArgument] = [
            .named(name: "name", value: name.toStarlark()),
            .named(name: "command_line_args", value: commandLineArgs.toStarlark())
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
            name: "ios_xctestrun_runner",
            arguments: lines
        )
    }
}

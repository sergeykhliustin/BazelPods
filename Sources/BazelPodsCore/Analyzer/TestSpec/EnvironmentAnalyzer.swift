//
//  EnvironmentAnalyzer.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 27.02.2024.
//

import Foundation

struct EnvironmentAnalyzer<S: SchemeRepresentable> {
    struct Result {
        var environmentVariables: [String: String]
        var launchArguments: [String]
    }
    private let spec: S
    private let options: BuildOptions

    init(spec: S,
         options: BuildOptions) {
        self.spec = spec
        self.options = options
    }

    var result: Result {
        return run()
    }

    private func run() -> Result {
        let launchArguments = spec.launchArguments.map({
            replacePodsEnvVars($0, options: options, absolutePath: true)
        })
        let environmentVariables = spec.environmentVariables.mapValues({
            replacePodsEnvVars($0, options: options, absolutePath: true)
        })
        return Result(
            environmentVariables: environmentVariables,
            launchArguments: launchArguments
        )
    }

}

//
//  PodDependenciesAnalyzer.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 08.02.2023.
//

import Foundation

public struct PodDependenciesAnalyzer {
    public struct Result {
        let dependencies: [String]
    }
    private let platform: Platform
    private let spec: PodSpec
    private let subspecs: [PodSpec]
    private let options: BuildOptions

    public init(platform: Platform,
                spec: PodSpec,
                subspecs: [PodSpec],
                options: BuildOptions) {
        self.platform = platform
        self.spec = spec
        self.subspecs = subspecs
        self.options = options
    }

    public var result: Result {
        return run()
    }

    private func run() -> Result {
        var dependencies = spec
            .collectAttribute(with: subspecs, keyPath: \.dependencies)
            .platform(platform) ?? []
        dependencies = dependencies
            .compactMap({ getDependencyName(podDepName: $0, podName: spec.name, options: options) })
        dependencies = Set(dependencies).sorted()

        return Result(dependencies: dependencies)
    }

    private func getDependencyName(podDepName: String, podName: String, options: BuildOptions) -> String? {
        let results = podDepName.components(separatedBy: "/")
        if results.count > 1 && results[0] == podName {
            // This is a local subspec reference
            return nil
        } else {
            if results.count > 1 {
                return options.getRulePrefix(name: results[0])
            } else {
                // This is a reference to another pod library
                return options.getRulePrefix(name: bazelLabel(fromString: results[0]))
            }
        }
    }
}

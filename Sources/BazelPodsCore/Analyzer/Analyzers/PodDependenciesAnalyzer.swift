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
    private let targetName: TargetName

    init(platform: Platform,
         spec: PodSpec,
         subspecs: [PodSpec],
         options: BuildOptions,
         targetName: TargetName) {
        self.platform = platform
        self.spec = spec
        self.subspecs = subspecs
        self.options = options
        self.targetName = targetName
    }

    public var result: Result {
        return run()
    }

    private func run() -> Result {
        var dependencies = spec
            .collectAttribute(with: subspecs, keyPath: \.dependencies)
            .platform(platform) ?? []
        dependencies = dependencies
            .compactMap({ getDependencyName(podDepName: $0, podName: spec.name) })
        dependencies = Set(dependencies).sorted()

        return Result(dependencies: dependencies)
    }

    private func getDependencyName(podDepName: String, podName: String) -> String? {
        let results = podDepName.components(separatedBy: "/")
        if results.count > 1 {
            if results[0] == podName {
                // This is a local subspec reference
                return nil
            } else {
                return results[0]
            }
        } else {
            return podDepName
        }
    }
}

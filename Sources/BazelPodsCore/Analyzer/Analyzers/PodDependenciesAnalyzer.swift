//
//  PodDependenciesAnalyzer.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 08.02.2023.
//

import Foundation

struct PodDependenciesAnalyzer<S: PodDependenciesRepresentable> {
    struct Result {
        let dependencies: [String]
    }
    private let platform: Platform
    private let spec: S
    private let subspecs: [S]
    private let options: BuildOptions
    private let targetName: TargetName

    init(platform: Platform,
         spec: S,
         subspecs: [S],
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
            .compactMap({ getDependencyName(podDepName: $0, podName: options.podName) })
        dependencies = Set(dependencies)
            .sorted()
            .map({
                targetName.podDependency($0, options: options)
            })

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

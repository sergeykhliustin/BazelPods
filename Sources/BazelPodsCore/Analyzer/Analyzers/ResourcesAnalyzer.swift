//
//  ResourcesAnalyzer.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 05.02.2023.
//

import Foundation

public struct ResourcesAnalyzer {
    public struct Result {
        struct Bundle {
            let name: String
            let resources: [String]
        }
        var resources: [String]
        var precompiledBundles: [String]
        var resourceBundles: [Bundle]
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
        let attr = spec
            .collectAttribute(with: subspecs, keyPath: \.resources)
            .platform(platform) ?? []
        let resources = extractResources(attr)
        let bundles = extractBundles(attr)
        let resourceBundles = spec
            .collectAttribute(with: subspecs, keyPath: \.resourceBundles)
            .platform(platform)?
            .mapValues({
                extractResources($0)
            })
            .map({ Result.Bundle(name: $0.key, resources: $0.value) })
            .sorted(by: { $0.name < $1.name }) ?? []

        return Result(resources: resources,
                      precompiledBundles: bundles,
                      resourceBundles: resourceBundles)
    }

    func extractResources(_ patterns: [String]) -> [String] {
        return patterns
            .filter({ !$0.hasSuffix(".bundle") })
            .flatMap { (p: String) -> [String] in
                pattern(fromPattern: p, includingFileTypes: []).map({
                    var components = $0.components(separatedBy: "/")
                    if let last = components.last {
                        var fixed = last
                            .replacingOccurrences(of: "xcassets", with: "xcassets/**")
                        //                    .replacingOccurrences(of: "lproj", with: "lproj")
                        if fixed.isEmpty || fixed == "*" {
                            fixed = "**"
                        }
                        components.removeLast()
                        components.append(fixed)
                    }
                    return components.joined(separator: "/")
                })
                .sorted()
            }
    }

    func extractBundles(_ patterns: [String]) -> [String] {
        patterns.reduce([String: String]()) { partialResult, pattern in
            guard pattern.hasSuffix(".bundle") else { return partialResult }
            var result = partialResult
            let absolutePattern = options.podTargetAbsoluteRoot.appendingPath(pattern)
            podGlob(pattern: absolutePattern)
                .map({ options.relativePath(from: $0) })
                .filter({ !$0.isEmpty })
                .forEach({
                    if result[$0.lastPath] != nil {
                        log_warning("duplicate bundle \($0.lastPath). Will use first matched.")
                    } else {
                        result[$0.lastPath] = $0
                    }
                })
            return result
        }
        .values
        .sorted()
    }
}

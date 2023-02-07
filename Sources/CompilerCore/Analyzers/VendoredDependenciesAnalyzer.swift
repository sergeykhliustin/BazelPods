//
//  VendoredDependenciesAnalyzer.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 06.02.2023.
//

import Foundation

public struct VendoredDependenciesAnalyzer {
    public struct Result {
        struct Library {
            let name: String
            let path: String
            let archs: [Arch]
        }
        struct Framework {
            let name: String
            let path: String
            let archs: [Arch]
            let dynamic: Bool
        }
        let libraries: [Library]
        let frameworks: [Framework]
        let xcFrameworks: [String]
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
        let frameworksAttr = spec
            .collectAttribute(with: subspecs, keyPath: \.vendoredFrameworks)
            .platform(platform) ?? []
        let frameworks = frameworksAttr.filter({ $0.pathExtention == "framework" })
        let xcFrameworks = frameworksAttr.filter({ $0.pathExtention == "xcframework" })
        let libraries = spec
            .collectAttribute(with: subspecs, keyPath: \.vendoredLibraries)
            .platform(platform) ?? []
        let supportedArchs = platform.supportedArchs
        let resultXCFrameworks = processXCFrameworks(xcFrameworks)
        let resultLibraries = processLibraries(libraries, supportedArchs: supportedArchs)
        let resultFrameworks = processFrameworks(frameworks, supportedArchs: supportedArchs)

        return Result(libraries: resultLibraries, frameworks: resultFrameworks, xcFrameworks: resultXCFrameworks)
    }

    private func processXCFrameworks(_ xcframeworks: [String]) -> [String] {
        let result = xcframeworks.reduce(Set<String>()) { partialResult, pattern in
            var result = partialResult
            let paths = podGlob(pattern: options.absolutePath(from: pattern))
                .map({ options.relativePath(from: $0) })
            paths.forEach({ result.insert($0) })
            return result
        }
            .sorted()
        return result
    }

    private func processLibraries(_ libraries: [String], supportedArchs: [Arch]) -> [Result.Library] {
        return libraries.reduce([Result.Library]()) { partialResult, path in
            var result = partialResult
            let name = path.deletingPathExtension.lastPath
            let absolutePath = options.podTargetAbsoluteRoot.appendingPath(path)
            let archs = Arch
                .archs(forExecutable: absolutePath)
                .filter({ supportedArchs.contains($0) })
            if !archs.isEmpty {
                result.append(.init(name: name, path: path, archs: archs))
            }
            return result
        }
    }

    private func processFrameworks(_ frameworks: [String], supportedArchs: [Arch]) -> [Result.Framework] {
        return frameworks.reduce([Result.Framework]()) { partialResult, pattern in
            var result = partialResult
            podGlob(pattern: options.podTargetAbsoluteRoot.appendingPath(pattern)).forEach({ absolutePath in
                let name = absolutePath.deletingPathExtension.lastPath
                let executable = absolutePath.appendingPath(name)
                let dynamic = isDynamicFramework(executable)
                let archs = Arch
                    .archs(forExecutable: executable)
                    .filter({ supportedArchs.contains($0) })
                if !archs.isEmpty {
                    result.append(.init(name: name,
                                        path: options.relativePath(from: absolutePath),
                                        archs: archs,
                                        dynamic: dynamic))
                }
            })

            return result
        }
    }
}

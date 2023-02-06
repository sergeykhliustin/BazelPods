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
            .collectAttribute(with: subspecs, keyPath: \.frameworks)
            .platform(platform) ?? []
        let frameworks = frameworksAttr.filter({ $0.pathExtention == ".framework" })
        let xcFrameworks = frameworksAttr.filter({ $0.pathExtention == ".xcframework" })
        let libraries = spec
            .collectAttribute(with: subspecs, keyPath: \.vendoredLibraries)
            .platform(platform) ?? []
        let platformArchs = platform.supportedArchs
        let resultLibraries = libraries.reduce([Result.Library]()) { partialResult, path in
            var result = partialResult
            let name = path.deletingPathExtension.lastPath
            let absolutePath = options.podTargetAbsoluteRoot.appendingPath(path)
            let archs = Arch
                .archs(forExecutable: absolutePath)
                .filter({ platformArchs.contains($0) })
            if !archs.isEmpty {
                result.append(.init(name: name, path: path, archs: archs))
            }
            return result
        }
        let resultFrameworks = frameworks.reduce([Result.Framework]()) { partialResult, path in
            var result = partialResult
            let name = path.deletingPathExtension.lastPath
            let absolutePath = options.podTargetAbsoluteRoot.appendingPath(path)
            let executable = absolutePath.appendingPath(name)
            let dynamic = isDynamicFramework(executable)
            let archs = Arch
                .archs(forExecutable: executable)
                .filter({ platformArchs.contains($0) })
            if !archs.isEmpty {
                result.append(.init(name: name, path: path, archs: archs, dynamic: dynamic))
            }
            return result
        }

        return Result(libraries: resultLibraries, frameworks: resultFrameworks, xcFrameworks: xcFrameworks)
    }
}

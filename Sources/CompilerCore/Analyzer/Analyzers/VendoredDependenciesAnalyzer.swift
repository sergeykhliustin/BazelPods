//
//  VendoredDependenciesAnalyzer.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 06.02.2023.
//

import Foundation

public struct VendoredDependenciesAnalyzer {
    public struct Result {
        struct Vendored {
            let name: String
            let path: String
            let archs: [Arch]
            let dynamic: Bool
        }
        var libraries: [Vendored]
        var frameworks: [Vendored]
        var xcFrameworks: [Vendored]
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
        let resultLibraries = processLibraries(libraries, supportedArchs: supportedArchs)
        let resultFrameworks = processFrameworks(frameworks, supportedArchs: supportedArchs)
        let resultXCFrameworkPaths = processXCFrameworks(xcFrameworks)
        let resultXCFrameworks = resultXCFrameworkPaths
            .compactMap({ processXCFramework($0, supportedArchs: supportedArchs) })

        return Result(libraries: resultLibraries,
                      frameworks: resultFrameworks,
                      xcFrameworks: resultXCFrameworks)
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

    private func processXCFramework(_ xcframework: String, supportedArchs: [Arch]) -> Result.Vendored? {
        let name = xcframework.deletingPathExtension.lastPath
        let absolutePath = options.absolutePath(from: xcframework)
        let frameworks = podGlob(pattern: absolutePath.appendingPath("**/*.framework"))
        let libraries = podGlob(pattern: absolutePath.appendingPath("**/*.a"))
        let librariesArchs = libraries
            .reduce(Set<Arch>(), { partialResult, library in
                var result = partialResult
                let archs = Arch.archs(forExecutable: library)
                archs.forEach({
                    if supportedArchs.contains($0) {
                        result.insert($0)
                    }
                })
                return result
            })
            .sorted()
        let (frameworksArchsSet, dynamic) = frameworks
            .reduce((Set<Arch>(), [Bool]())) { partialResult, framework in
                let name = framework.deletingPathExtension.lastPath
                let executable = framework.appendingPath(name)
                var (resultArchs, resultDynamic) = partialResult
                let archs = Arch.archs(forExecutable: executable).filter({ supportedArchs.contains($0) })
                if !archs.isEmpty {
                    let dynamic = isDynamicFramework(executable)
                    resultDynamic.append(dynamic)
                }
                archs.forEach({
                    resultArchs.insert($0)
                })
                return (resultArchs, resultDynamic)
            }
        let frameworksArchs = frameworksArchsSet.sorted()
        if !librariesArchs.isEmpty && !frameworksArchs.isEmpty {
            log_warning("xcframework contains libraries and frameworks for \(platform), undefined behaviour: \(xcframework)")
        }

        if !librariesArchs.isEmpty {
            return Result.Vendored(name: name, path: xcframework, archs: librariesArchs, dynamic: false)
        } else if !frameworksArchs.isEmpty {
            if !(dynamic.allSatisfy({ $0 == true }) || dynamic.allSatisfy({ $0 == false })) {
                log_warning("xcframework undefined linkage: \(xcframework)")
            }
            let isDynamic = dynamic.allSatisfy({ $0 == true })
            return Result.Vendored(name: name, path: xcframework, archs: frameworksArchs, dynamic: isDynamic)
        } else {
            log_error("unable to process: \(xcframework)")
        }
        return nil
    }

    private func processLibraries(_ libraries: [String], supportedArchs: [Arch]) -> [Result.Vendored] {
        return libraries.reduce([Result.Vendored]()) { partialResult, path in
            var result = partialResult
            let name = path.deletingPathExtension.lastPath
            let absolutePath = options.absolutePath(from: path)
            let archs = Arch
                .archs(forExecutable: absolutePath)
                .filter({ supportedArchs.contains($0) })
            if !archs.isEmpty {
                result.append(.init(name: name, path: path, archs: archs, dynamic: false))
            }
            return result
        }
    }

    private func processFrameworks(_ frameworks: [String], supportedArchs: [Arch]) -> [Result.Vendored] {
        return frameworks.reduce([Result.Vendored]()) { partialResult, pattern in
            var result = partialResult
            podGlob(pattern: options.absolutePath(from: pattern)).forEach({ absolutePath in
                let name = absolutePath.deletingPathExtension.lastPath
                let executable = absolutePath.appendingPath(name)
                let dynamic = isDynamicFramework(executable)
                let archs = Arch
                    .archs(forExecutable: executable)
                    .filter({ supportedArchs.contains($0) })
                if !archs.isEmpty && !absolutePath.contains(_ios_sim_arm64_) {
                    result.append(.init(name: name,
                                        path: options.relativePath(from: absolutePath),
                                        archs: archs,
                                        dynamic: dynamic))
                }
            })

            return result
        }
    }

    private func isDynamicFramework(_ executable: String) -> Bool {
        // TODO: Find proper way
        let output = SystemShellContext().command("/usr/bin/file", arguments: [executable])
            .standardOutputAsString
            .deletingPrefix(executable)
        return output.contains("dynamically")
    }
}

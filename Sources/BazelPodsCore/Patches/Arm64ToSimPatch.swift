//
//  Arm64ToSimPatch.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 17.02.2023.
//

import Foundation

private typealias Vendored = VendoredDependenciesAnalyzer.Result.Vendored

public struct Arm64ToSimPatch: Patch {
    private let options: BuildOptions
    private let platform: Platform
    private let nameSuffix: String
    private let outputPath: String

    public init(options: BuildOptions,
                platform: Platform,
                nameSuffix: String = "_ios_sim_arm64_",
                outputPath: String = "._ios_sim_arm64_") {
        self.options = options
        self.platform = platform
        self.nameSuffix = nameSuffix
        self.outputPath = outputPath
    }

    public func run(base: inout BaseAnalyzer.Result,
                    sources: inout SourcesAnalyzer.Result,
                    resources: inout ResourcesAnalyzer.Result,
                    sdkDeps: inout SdkDependenciesAnalyzer.Result,
                    vendoredDeps: inout VendoredDependenciesAnalyzer.Result,
                    podDeps: inout PodDependenciesAnalyzer.Result,
                    buildSettings: inout BuildSettingsAnalyzer.Result) {
        guard platform == .ios else { return }
        vendoredDeps.frameworks += vendoredDeps.frameworks.compactMap({ processFramework($0) })
        vendoredDeps.libraries += vendoredDeps.libraries.compactMap({ processLibrary($0) })
    }

    private func processLibrary(_ library: Vendored) -> Vendored? {
        guard !library.archs.contains(.ios_sim_arm64) else { return nil }
        log_info("Patching \(library.path.lastPath) to support ios_sim_arm64 ...")
        let path = options.absolutePath(from: library.path)
        let executableName = path.lastPath
        let enclosingPath = path.deletingLastPath
        let resultPath = enclosingPath.appendingPath(outputPath)
        let resultLibPath = resultPath.appendingPath(executableName)
        let tmpPath = NSTemporaryDirectory().appendingPath(UUID().uuidString)
        let fileManager = FileManager.default

        defer {
            try? fileManager.removeItem(atPath: tmpPath)
        }

        do {
            if !fileManager.fileExists(atPath: resultPath) {
                try fileManager.createDirectory(atPath: resultPath, withIntermediateDirectories: false)
            }
            try? fileManager.removeItem(atPath: tmpPath)
            if !fileManager.fileExists(atPath: tmpPath) {
                try fileManager.createDirectory(atPath: tmpPath, withIntermediateDirectories: false)
            }
            let tmpExecutable = tmpPath.appendingPath(executableName)
            try fileManager.copyItem(atPath: path, toPath: tmpExecutable)
            try processBinary(tmpPath: tmpPath, tmpExecutable: tmpExecutable, dynamic: library.dynamic)
            if !Arch.archs(forExecutable: tmpExecutable).contains(.ios_sim_arm64) {
                throw "arm64 to sim not patched"
            }
            if fileManager.fileExists(atPath: resultLibPath) {
                try fileManager.removeItem(atPath: resultLibPath)
            }
            try fileManager.copyItem(atPath: tmpExecutable, toPath: resultLibPath)
        } catch {
            log_error(error)
            try? fileManager.removeItem(atPath: resultPath.appendingPath(executableName))
            try? fileManager.removeItem(atPath: tmpPath)
            return nil
        }
        return Vendored(name: executableName + nameSuffix,
                        path: options.relativePath(from: resultLibPath),
                        archs: [.ios_sim_arm64],
                        dynamic: library.dynamic)
    }

    private func processFramework(_ framework: Vendored) -> Vendored? {
        guard !framework.archs.contains(.ios_sim_arm64) else { return nil }
        log_info("Patching \(framework.path.lastPath) to support ios_sim_arm64 ...")
        let name = framework.path.deletingPathExtension.lastPath
        let frameworkPath: String = options.absolutePath(from: framework.path)
        let executable = frameworkPath.appendingPath(name)
        let enclosingPath = frameworkPath.deletingLastPath
        let resultPath = enclosingPath.appendingPath(outputPath)
        let resultFrameworkPath = resultPath.appendingPath(frameworkPath.lastPath)
        let tmpPath = NSTemporaryDirectory().appendingPath(UUID().uuidString)
        let fileManager = FileManager.default
        defer {
            try? fileManager.removeItem(atPath: tmpPath)
        }
        do {
            if !fileManager.fileExists(atPath: resultPath) {
                try fileManager.createDirectory(atPath: resultPath, withIntermediateDirectories: false)
            }
            try? fileManager.removeItem(atPath: tmpPath)
            if !fileManager.fileExists(atPath: tmpPath) {
                try fileManager.createDirectory(atPath: tmpPath, withIntermediateDirectories: false)
            }
            let tmpExecutable = tmpPath.appendingPath(name)
            try fileManager.copyItem(atPath: executable, toPath: tmpExecutable)
            try processBinary(tmpPath: tmpPath, tmpExecutable: tmpExecutable, dynamic: framework.dynamic)
            if !Arch.archs(forExecutable: tmpExecutable).contains(.ios_sim_arm64) {
                throw "arm64 to sim not patched"
            }
            if frameworkPath != resultFrameworkPath {
                if fileManager.fileExists(atPath: resultFrameworkPath) {
                    try fileManager.removeItem(atPath: resultFrameworkPath)
                }
                try fileManager.copyItem(atPath: frameworkPath, toPath: resultFrameworkPath)
            }
            try fileManager.removeItem(atPath: resultFrameworkPath.appendingPath(name))
            try fileManager.copyItem(atPath: tmpExecutable, toPath: resultFrameworkPath.appendingPath(name))
        } catch {
            log_error(error)
            if frameworkPath != resultFrameworkPath {
                try? fileManager.removeItem(atPath: resultFrameworkPath)
            }
            return nil
        }

        return Vendored(name: name + nameSuffix,
                        path: options.relativePath(from: resultFrameworkPath),
                        archs: [.ios_sim_arm64],
                        dynamic: framework.dynamic)
    }

    private func processBinary(tmpPath: String, tmpExecutable: String, dynamic: Bool) throws {
        let fileManager = FileManager.default
        try thinBinary(tmpExecutable)
        if try isArchive(tmpExecutable) {
            try unarchive(dir: tmpPath, executable: tmpExecutable)
            let objects = try fileManager
                .contentsOfDirectory(atPath: tmpPath)
                .filter({ $0.pathExtention == "o" })
                .map({ tmpPath.appendingPath($0) })
            let processBlock: (String) throws -> Void = { object in
                let isDynamic = try isDynamic(object)
                try Transmogrifier.processBinary(atPath: object, outputPath: object, isDynamic: isDynamic)
            }
            if options.noConcurrency {
                try objects.forEach(processBlock)
            } else {
                let dGroup = DispatchGroup()
                var dError: Error?
                objects.forEach({ object in
                    dGroup.enter()
                    DispatchQueue.global().async {
                        do {
                            try processBlock(object)
                        } catch {
                            if dError == nil {
                                dError = error
                            }
                        }
                        dGroup.leave()
                    }
                })
                dGroup.wait()
                if let dError {
                    throw dError
                }
            }
            try fileManager.removeItem(atPath: tmpExecutable)
            try archive(dir: tmpPath, name: tmpExecutable.lastPath)
        } else {
            try Transmogrifier.processBinary(atPath: tmpExecutable, outputPath: tmpExecutable, isDynamic: dynamic)
        }
    }

    private func thinBinary(_ executable: String) throws {
        let output: CommandOutput = SystemShellContext()
            .command("/usr/bin/lipo", arguments: ["-thin", "arm64", executable, "-output", executable])
        if output.terminationStatus != 0 {
            throw output.standardErrorAsString
        }
    }

    private func unarchive(dir: String, executable: String) throws {
        let output = SystemShellContext()
            .shellOut("cd \(dir) && ar x \(executable)")
        if output.terminationStatus != 0 {
            throw output.standardErrorAsString
        }
    }

    private func archive(dir: String, name: String) throws {
        let output = SystemShellContext()
            .shellOut("cd \(dir) && ar crv \(name) *.o")
        if output.terminationStatus != 0 {
            throw output.standardErrorAsString
        }
    }

    private func isArchive(_ executable: String) throws -> Bool {
        let output: CommandOutput = SystemShellContext()
            .command("/usr/bin/file", arguments: [executable])
        if output.terminationStatus != 0 {
            throw output.standardErrorAsString
        }
        return output
            .standardOutputAsString
            .deletingPrefix(executable)
            .contains("ar archive")
    }

    private func isDynamic(_ object: String) throws -> Bool {
        let output: CommandOutput = SystemShellContext()
            .command("/usr/bin/file", arguments: [object])
        if output.terminationStatus != 0 {
            throw output.standardErrorAsString
        }
        return output
            .standardOutputAsString
            .deletingPrefix(object)
            .contains("dynamically")
    }

}

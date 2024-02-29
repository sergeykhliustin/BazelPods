//
//  RootCommand.swift
//  bazelpods
//
//  Created by Sergey Khliustin on 09.03.2023.
//

import Foundation
import ArgumentParser
import BazelPodsCore
import Logger

extension Platform: ExpressibleByArgument {}
extension LogLevel: ExpressibleByArgument {}
extension PatchType: ExpressibleByArgument {}
extension TestsTimeout: ExpressibleByArgument {}

func absolutePath(_ path: String, base: String) -> String {
    guard !path.starts(with: "/") else { return path }
    return base.appendingPath(path)
}

func getJSONPodspec(shell: ShellContext,
                    podspecName: String,
                    path: String,
                    src: String,
                    podsRoot: String,
                    useBundler: Bool) throws -> JSONDict {
    let jsonData: Data
    // Check the path and child paths
    let podspecPath = path
    if FileManager.default.fileExists(atPath: "\(podspecPath).json") {
        jsonData = shell.command("/bin/cat", arguments: [podspecPath + ".json"]).standardOutputData
    } else if let data = try? Data(contentsOf: URL(fileURLWithPath: absolutePath(podsRoot, base: src).appendingPath("\(podspecName)/\(podspecName).json"))) {
        jsonData = data
    } else if FileManager.default.fileExists(atPath: podspecPath) {
        // This uses the current environment's cocoapods installation.

        let commandBin: String
        let arguments: [String]

        if useBundler {
            let whichBundle = shell.shellOut("/usr/bin/which bundle").standardOutputAsString
            guard !whichBundle.isEmpty else {
                throw "BazelPods requires bundler installation on host"
            }
            let bundleBin = whichBundle.components(separatedBy: "\n")[0]
            commandBin = bundleBin
            arguments = ["exec", "pod", "ipc", "spec", podspecPath]
        } else {
            let whichPod = shell.shellOut("/usr/bin/which pod").standardOutputAsString
            if whichPod.isEmpty {
                throw "BazelPods requires a cocoapod installation on host"
            }
            let podBin = whichPod.components(separatedBy: "\n")[0]
            commandBin = podBin
            arguments = ["ipc", "spec", podspecPath]
        }

        let podResult = shell.command(commandBin, arguments: arguments)
        guard podResult.terminationStatus == 0 else {
            throw """
                    PodSpec decoding failed \(podResult.terminationStatus)
                    stdout: \(podResult.standardOutputAsString)
                    stderr: \(podResult.standardErrorAsString)
            """
        }
        jsonData = podResult.standardOutputData
    } else {
        throw "Missing podspec ( \(podspecPath) )"
    }

    guard let JSONFile = try? JSONSerialization.jsonObject(with: jsonData, options:
        JSONSerialization.ReadingOptions.allowFragments) as AnyObject,
        let JSONPodspec = JSONFile as? JSONDict
    else {
        throw "Invalid JSON Podspec"
    }
    return JSONPodspec
}

let isHostArm64 = SystemShellContext()
    .command("/usr/bin/arch")
    .standardOutputAsString
    .trimmingCharacters(in: .whitespacesAndNewlines) == "arm64"

func configureLogger(color: ColorMode, logLevel: LogLevel, prefix: String? = nil) {
    switch color {
    case .auto:
        logger.colors = getenv("TERM") != nil
    case .yes:
        logger.colors = true
    case .no:
        logger.colors = false
    }
    logger.prefix = prefix
    logger.level = logLevel
}

@main
struct BazelPods: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "bazelpods",
        abstract: "One more way to convert CocoaPods into Bazel.",
        subcommands: [Generate.self, Compile.self],
        defaultSubcommand: Generate.self)

    struct Options: ParsableArguments {
        @Option(name: .long, help: "Sources root where Pods directory located (or renamed by podsRoot)")
        var src: String

        @Option(parsing: .upToNextOption,
                help: """
            Space separated platforms.
            Valid values are: ios, osx, tvos, watchos.
            """)
        var platforms: [Platform] = [.ios]

        @Option(name: .long, help: "Minimum iOS version")
        var minIos: String = BasicBuildOptions.defaultVersion(for: .ios)

        @Option(name: .long, parsing: .upToNextOption, help: """
    Patches. It will be applied in the order listed here.
    Available options: \(PatchType.allValueStrings.joined(separator: ", ")).
    \(PatchType.user_options.rawValue) requires --user-options configured.
    If 'user_options' not specified, but --user_options exist, user_options patch are applied automatically.
    """
        )
        var patches: [PatchType] = []

        @Option(name: .long, parsing: .upToNextOption,
                help: """
User extra options.
Supported fields: \(UserOption.KeyPath.allCases.map({ "'\($0.rawValue)'" }).joined(separator: ", ")).
Supported operators: \(UserOption.Opt.allCases.map({ "'\($0.rawValue)' (\($0.description))" }).joined(separator: ", ")).
Example:
'SomePod.sdk_dylibs += something,something'
'SomePod.testonly := true'
Platform specific:
'SomePod.platform_ios.sdk_dylibs += something,something'
For test specs:
'SomePod/UnitTests.runner := //:SomeTestsRunner'
"""
        )
        var userOptions: [String] = []

        @Option(name: .long, help: "Dependencies prefix")
        var depsPrefix: String = "//Pods"

        @Option(name: .long, help: "Pods root relative to workspace. Used for headers search paths")
        var podsRoot: String = "Pods"

        @Flag(name: .shortAndLong, help: "Packaging pods in dynamic frameworks if possible (same as `use_frameworks!`)")
        var frameworks: Bool = false

        @Flag(name: .long, help: "Disable concurrency.")
        var noConcurrency: Bool = false

        @Option(help: "Log level (\(LogLevel.allCases.map({ $0.rawValue }).joined(separator: "|")))")
        var logLevel: LogLevel = .info

        @Flag(help: "Option to use `bundle exec` for `pod` calls")
        var useBundler: Bool = false

        @Option(help: "(Optional) Default timeout for test targets (\(TestsTimeout.allCases.map({ $0.rawValue }).joined(separator: "|")))")
        var testsTimeout: TestsTimeout?
    }
}

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
    }
}

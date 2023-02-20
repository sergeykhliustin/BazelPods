//
//  MainCommand.swift
//  PodToBUILD
//
//  Created by Sergey Khliustin on 26.08.2022.
//

import Foundation
import ArgumentParser
import CompilerCore
import ObjcSupport
import Logger

extension Platform: ExpressibleByArgument {}
extension LogLevel: ExpressibleByArgument {}
extension PatchType: ExpressibleByArgument {}

struct RootCommand: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "Compiler", abstract: "Compiles podspec.json to BUILD file")

    @Option(name: .long, help: "Sources root where Pods directory located (or renamed by podsRoot)")
    var src: String

    @Option(help: "podspec.json", completion: .file(extensions: ["json"]))
    var podspec: String

    @Option(name: .long, parsing: .upToNextOption, help: "Subspecs list")
    var subspecs: [String] = []

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

    @Option(help: "Log level (\(LogLevel.allCases.map({ $0.rawValue }).joined(separator: "|")))")
    var logLevel: LogLevel = .info

    func run() throws {
        _ = CrashReporter()
        logger.level = logLevel
        let jsonData = try NSData(contentsOfFile: podspec, options: []) as Data
        let jsonFile = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as AnyObject

        guard let jsonPodspec = jsonFile as? JSONDict else {
            throw "Error parsing podspec at path \(podspec)"
        }

        let userOptions = userOptions
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            .filter({ !$0.isEmpty })
            .compactMap({ UserOption($0) })

        let podSpec = try PodSpec(JSONPodspec: jsonPodspec)

        let podSpecURL = NSURL(fileURLWithPath: podspec)
        let assumedPodName = podSpecURL.lastPathComponent!.components(separatedBy: ".")[0]
        let options = BasicBuildOptions(podName: assumedPodName,
                                        subspecs: subspecs,
                                        sourcePath: src,
                                        platforms: platforms,
                                        patches: patches,
                                        userOptions: userOptions,
                                        minIosPlatform: minIos,
                                        depsPrefix: depsPrefix,
                                        podsRoot: podsRoot,
                                        useFrameworks: frameworks)

        let result = PodBuildFile.with(podSpec: podSpec, buildOptions: options).compile()
        print(result)
    }

    func absolutePath(_ path: String) -> String {
        guard !path.starts(with: "/") else { return path }
        return (src as NSString).appendingPathComponent(path)
    }
}

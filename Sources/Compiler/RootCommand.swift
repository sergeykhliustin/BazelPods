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

extension Platform: ExpressibleByArgument {}

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
            Currently ignored, only 'ios' supported
            """)
    var platforms: [Platform] = [.ios]

    @Option(name: .long, help: "Minimum iOS version")
    var minIos: String = BasicBuildOptions.defaultVersion(for: .ios)

    @Option(name: .long, help: "Dependencies prefix")
    var depsPrefix: String = "//Pods"

    @Option(name: .long, help: "Pods root relative to workspace. Used for headers search paths")
    var podsRoot: String = "Pods"

    @Flag(name: .shortAndLong, help: "Packaging pods in dynamic frameworks if possible (same as `use_frameworks!`)")
    var frameworks: Bool = false

    @Option(name: .long, parsing: .upToNextOption,
            help: """
User extra options.
Supported fields for '+=' (add): 'sdk_dylibs', 'sdk_frameworks', 'weak_sdk_frameworks', 'deps'.
Supported fields for '-=' (remove): 'sdk_dylibs', 'sdk_frameworks', 'weak_sdk_frameworks', 'deps'.
Supported fields for ':=' (override): 'testonly', 'link_dynamic'.
Example:
'SomePod.sdk_dylibs += something,something'
'SomePod.testonly := true'
"""
    )
    var userOptions: [String] = []

    func run() throws {
        _ = CrashReporter()
        let jsonData = try NSData(contentsOfFile: podspec, options: []) as Data
        let jsonFile = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as AnyObject

        guard let jsonPodspec = jsonFile as? JSONDict else {
            throw "Error parsing podspec at path \(podspec)"
        }

        let podSpec = try PodSpec(JSONPodspec: jsonPodspec)

        let podSpecURL = NSURL(fileURLWithPath: podspec)
        let assumedPodName = podSpecURL.lastPathComponent!.components(separatedBy: ".")[0]
        let options = BasicBuildOptions(podName: assumedPodName,
                                        subspecs: subspecs,
                                        sourcePath: src,
                                        platforms: platforms,
                                        userOptions: userOptions,
                                        minIosPlatform: minIos,
                                        depsPrefix: depsPrefix,
                                        podsRoot: podsRoot,
                                        dynamicFrameworks: frameworks)

        let result = PodBuildFile.with(podSpec: podSpec, buildOptions: options).compile()
        print(result)
    }

    func absolutePath(_ path: String) -> String {
        guard !path.starts(with: "/") else { return path }
        return (src as NSString).appendingPathComponent(path)
    }
}

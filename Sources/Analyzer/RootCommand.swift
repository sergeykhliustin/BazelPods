//
//  MainCommand.swift
//  Analyzer
//
//  Created by Sergey Khliustin on 05.02.2023.
//

import Foundation
import ArgumentParser
import CompilerCore

struct RootCommand: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "Analyzer", abstract: "Analyzer for podspec.json")
    @Argument(help: "podspec.json", completion: .file(extensions: ["json"]))
    var podspecJson: String

    @Option(name: .long, help: "Sources root where Pods directory located (or renamed by podsRoot)")
    var src: String = ""

    @Option(name: .long, parsing: .upToNextOption, help: "Subspecs list")
    var subspecs: [String] = []

    @Option(name: .long, help: "Minimum iOS version to bump if lower")
    var minIos: String?

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
        let jsonData = try NSData(contentsOfFile: podspecJson, options: []) as Data
        let jsonFile = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as AnyObject

        guard let jsonPodspec = jsonFile as? JSONDict else {
            throw "Error parsing podspec at path \(podspecJson)"
        }

        let podSpec = try PodSpec(JSONPodspec: jsonPodspec)

        let podSpecURL = NSURL(fileURLWithPath: podspecJson)
        let assumedPodName = podSpecURL.lastPathComponent!.components(separatedBy: ".")[0]
        let options = BasicBuildOptions(podName: assumedPodName,
                                        subspecs: subspecs,
                                        sourcePath: src,
                                        userOptions: userOptions,
                                        minIosPlatform: minIos,
                                        depsPrefix: depsPrefix,
                                        podsRoot: podsRoot,
                                        dynamicFrameworks: frameworks)

        let podSubSpecs = podSpec.selectedSubspecs(subspecs: subspecs)

        let sourcesResult = SourcesAnalyzer(platform: .ios, spec: podSpec, subspecs: podSubSpecs, options: options).result
        let baseInfoResult = BaseInfoAnalyzer(platform: .ios, spec: podSpec, subspecs: podSubSpecs, options: options).result
        let resourcesResult = ResourcesAnalyzer(platform: .ios, spec: podSpec, subspecs: podSubSpecs, options: options).result
        print(sourcesResult)
        print(baseInfoResult)
        print(resourcesResult)
    }
}

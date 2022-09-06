//
//  MainCommand.swift
//  PodToBUILD
//
//  Created by Sergey Khliustin on 26.08.2022.
//

import Foundation
import ArgumentParser
import PodToBUILD
import ObjcSupport

struct RootCommand: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "Compiler", abstract: "Compiles podspec.json to BUILD file")
    @Argument(help: "podspec.json", completion: .file(extensions: ["json"]))
    var podspecJson: String

    @Option(name: .long, help: "Sources root where Pods directory located (or renamed by podsRoot)")
    var src: String = ""

    @Option(name: .long, parsing: .upToNextOption, help: "Subspecs list")
    var subspecs: [String] = []

    @Option(name: .long, help: "Minimum iOS version if not listed in podspec")
    var minIos: String = "13.0"

    @Option(name: .long, help: "Dependencies prefix")
    var depsPrefix: String = "//Pods"

    @Option(name: .long, help: "Pods root relative to workspace. Used for headers search paths")
    var podsRoot: String = "Pods"

    @Flag(name: .shortAndLong, help: "Packaging pods in dynamic frameworks (same as `use_frameworks!`)")
    var frameworks: Bool = false

    func run() throws {
        _ = CrashReporter()
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
                                        iosPlatform: minIos,
                                        depsPrefix: depsPrefix,
                                        podsRoot: podsRoot,
                                        linkDynamic: frameworks)

        let result = PodBuildFile.with(podSpec: podSpec, buildOptions: options).compile()
        print(result)
    }

    func absolutePath(_ path: String) -> String {
        guard !path.starts(with: "/") else { return path }
        return (src as NSString).appendingPathComponent(path)
    }
}

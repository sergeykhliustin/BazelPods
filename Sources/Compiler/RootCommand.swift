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

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

struct RootCommand: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "Compiler", abstract: "Compiles podspec.json to BUILD file")
    @Argument(help: "podspec.json", completion: .file(extensions: ["json"]))
    var podspecJson: String

    @Option(name: .long, help: "Sources root")
    var src: String?

    @Option(name: .long, parsing: .upToNextOption, help: "Subspecs list")
    var subspecs: [String] = []

    @Option(name: .long, help: "Minimum iOS version if not listed in podspec")
    var minIos: String = "13.0"

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
                                        iosPlatform: minIos)

        let result = PodBuildFile.with(podSpec: podSpec, buildOptions: options).compile()
        print(result)
    }

    func absolutePath(_ path: String) -> String {
        guard let src = src else { return path }
        guard !path.starts(with: "/") else { return path }
        return (src as NSString).appendingPathComponent(path)
    }
}

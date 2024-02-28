//
//  Compile.swift
//  bazelpods
//
//  Created by Sergey Khliustin on 09.03.2023.
//

import Foundation
import ArgumentParser
import BazelPodsCore
import ObjcSupport
import Logger

extension BazelPods {
    struct Compile: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Compiles podspec.json to BUILD file")

        @OptionGroup var options: BazelPods.Options

        @Option(help: "podspec.json", completion: .file(extensions: ["json"]))
        var podspec: String

        @Option(name: .long, parsing: .upToNextOption, help: "Subspecs list")
        var subspecs: [String] = []

        func run() throws {
            _ = CrashReporter()
            logger.level = options.logLevel
            let jsonData = try NSData(contentsOfFile: podspec, options: []) as Data
            let jsonFile = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as AnyObject

            guard let jsonPodspec = jsonFile as? JSONDict else {
                throw "Error parsing podspec at path \(podspec)"
            }

            let userOptions = options.userOptions
                .map({ $0.trimmingCharacters(in: .whitespaces) })
                .filter({ !$0.isEmpty })
                .compactMap({ UserOption($0) })

            let podSpec = try PodSpec(JSONPodspec: jsonPodspec)

            let podSpecURL = NSURL(fileURLWithPath: podspec)
            let assumedPodName = podSpecURL.lastPathComponent!.components(separatedBy: ".")[0]
            let options = BasicBuildOptions(podName: assumedPodName,
                                            subspecs: subspecs,
                                            sourcePath: options.src,
                                            platforms: options.platforms,
                                            patches: options.patches,
                                            userOptions: userOptions,
                                            minIosPlatform: options.minIos,
                                            depsPrefix: options.depsPrefix,
                                            podsRoot: options.podsRoot,
                                            useFrameworks: options.frameworks,
                                            noConcurrency: options.noConcurrency,
                                            hostArm64: isHostArm64,
                                            testsTimeout: options.testsTimeout)

            let result = PodBuildFile.with(podSpec: podSpec, buildOptions: options).compile()
            print(result)
        }
    }
}

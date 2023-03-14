//
//  Arm64Sim.swift
//  bazelpods
//
//  Created by Sergey Khliustin on 10.03.2023.
//

import Foundation
import ArgumentParser
import ObjcSupport
import BazelPodsCore

extension BazelPods {
    struct Arm64sim: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Converts existing frameworks and static libs to arm64 simulator")

        @OptionGroup var options: BazelPods.Options

        @Option(help: "Pods.json")
        var podsJson: String = "Pods/Pods.json"

        @Option(name: .long, parsing: .upToNextOption, help: "Subspecs list")
        var subspecs: [String] = []

        @Flag(name: .long, help: "By default it will run only on arm64 host. Use this option to override.")
        var force: Bool = false

        func run() throws {
            _ = CrashReporter()
            guard isHostArm64 && !force else { return }
            configureLogger(color: .auto, logLevel: options.logLevel)
            let data = try NSData(contentsOfFile: absolutePath(podsJson, base: options.src), options: [])
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let json = try decoder.decode([String: PodConfig].self, from: data as Data)
            let specifications = PodSpecification.resolve(with: json).sorted(by: { $0.name < $1.name })
            for specification in specifications {
                try process(specification: specification, userOptions: [])
            }
        }

        private func process(specification: PodSpecification, userOptions: [UserOption]) throws {
            guard options.platforms == [.ios] else { return }
            let podSpec: PodSpec
            let name = specification.name
            if specification.podspec.hasSuffix(".json") {
                let jsonData = try NSData(contentsOfFile: absolutePath(specification.podspec, base: options.src), options: []) as Data
                let jsonFile = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
                guard let jsonPodspec = jsonFile as? JSONDict else {
                    throw "Error parsing podspec at path \(specification.podspec)"
                }
                podSpec = try PodSpec(JSONPodspec: jsonPodspec)
            } else {
                let jsonPodspec = try getJSONPodspec(shell: SystemShellContext(trace: false),
                                                     podspecName: name,
                                                     path: absolutePath(specification.podspec, base: options.src),
                                                     src: options.src,
                                                     podsRoot: options.podsRoot)
                podSpec = try PodSpec(JSONPodspec: jsonPodspec)
            }

            let buildOptions = BasicBuildOptions(podName: name,
                                                 subspecs: specification.subspecs,
                                                 sourcePath: options.src,
                                                 platforms: options.platforms,
                                                 patches: options.patches,
                                                 userOptions: userOptions,
                                                 minIosPlatform: options.minIos,
                                                 depsPrefix: options.depsPrefix,
                                                 podsRoot: options.podsRoot,
                                                 useFrameworks: options.frameworks,
                                                 noConcurrency: options.noConcurrency,
                                                 hostArm64: isHostArm64)
            var analyzer = try Analyzer(
                platform: .ios,
                spec: podSpec,
                subspecs: podSpec.selectedSubspecs(subspecs: specification.subspecs),
                options: buildOptions)
            analyzer.patch(Arm64ToSimPatch(options: buildOptions, platform: .ios, nameSuffix: "", outputPath: ""))
        }
    }
}

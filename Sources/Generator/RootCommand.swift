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
    static var configuration = CommandConfiguration(commandName: "Generator",
                                                    abstract: "Generates BUILD files for pods")
    @Argument(help: "Pods.json")
    var podsJson: String

    @Option(name: .long, help: "Sources root where Pods directory located (or renamed by podsRoot)")
    var src: String

    @Option(name: .long, help: "Minimum iOS version if not listed in podspec")
    var minIos: String = "13.0"

    @Option(name: .long, help: "Dependencies prefix")
    var depsPrefix: String = "//Pods"

    @Option(name: .long, help: "Pods root relative to workspace. Used for headers search paths")
    var podsRoot: String = "Pods"

    @Flag(name: .shortAndLong, help: "Packaging pods in dynamic frameworks (same as `use_frameworks!`)")
    var frameworks: Bool = false

    @Flag(name: .shortAndLong, help: "Concurrent mode for generating files faster")
    var concurrent: Bool = false

    @Flag(name: .shortAndLong, help: "Print BUILD files contents to terminal output")
    var printOutput: Bool = false

    @Flag(name: .shortAndLong, help: "Debug mode. Files will not be written")
    var debug: Bool = false

    @Flag(name: .shortAndLong, help: "Will add podspec.json to the pod directory. Just for debugging purposes.")
    var addPodspec: Bool = false

    func run() throws {
        _ = CrashReporter()
        let data = try NSData(contentsOfFile: absolutePath(podsJson), options: [])
        let json = try JSONDecoder().decode([String: PodConfig].self, from: data as Data)

        let specifications = PodSpecification.resolve(with: json).sorted(by: { $0.name < $1.name })
        let compiler: (PodSpecification) throws -> Void = { specification in
            print("Generating: \(specification.name)" +
                  (specification.subspecs.isEmpty ? "" : " \n\tsubspecs: " +
                   specification.subspecs.joined(separator: " ")))
            let podSpec: PodSpec
            var podSpecJson: JSONDict?
            if specification.podspec.hasSuffix(".json") {
                let jsonData = try NSData(contentsOfFile: absolutePath(specification.podspec), options: []) as Data
                let jsonFile = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
                guard let jsonPodspec = jsonFile as? JSONDict else {
                    throw "Error parsing podspec at path \(specification.podspec)"
                }
                podSpec = try PodSpec(JSONPodspec: jsonPodspec)
                podSpecJson = jsonPodspec
            } else {
                let jsonPodspec = try getJSONPodspec(shell: SystemShellContext(trace: false),
                                                     podspecName: specification.name,
                                                     path: absolutePath(specification.podspec))
                podSpec = try PodSpec(JSONPodspec: jsonPodspec)
                podSpecJson = jsonPodspec
            }

            // Consider adding a split here to split out sublibs
            let buildOptions = BasicBuildOptions(podName: specification.name,
                                                 subspecs: specification.subspecs,
                                                 podspecPath: specification.podspec,
                                                 sourcePath: src,
                                                 iosPlatform: minIos,
                                                 depsPrefix: depsPrefix,
                                                 podsRoot: podsRoot,
                                                 linkDynamic: frameworks)
            let starlarkString = PodBuildFile
                .with(podSpec: podSpec, buildOptions: buildOptions)
                .compile()

            if printOutput {
                print(starlarkString)
            }
            if !debug {
                if specification.development &&
                    !FileManager.default.fileExists(atPath: absolutePath("Pods/\(specification.name)")) {
                    try? FileManager.default.createDirectory(atPath: absolutePath("Pods/\(specification.name)"),
                                                             withIntermediateDirectories: false)
                    let contents = (try? FileManager.default.contentsOfDirectory(atPath: src)) ?? []
                    contents.forEach({ file in
                        let sourcePath = absolutePath(file)
                        let symlinkPath = absolutePath("Pods/\(specification.name)/\(file)")
                        do {
                            try FileManager.default.createSymbolicLink(atPath: symlinkPath,
                                                                       withDestinationPath: sourcePath)
                        } catch {
                            print("Error creating symlink: \(error)")
                        }
                    })
                }
                let filePath = "Pods/\(specification.name)/BUILD.bazel"
                if let data = starlarkString.data(using: .utf8) {
                    try data.write(to: URL(fileURLWithPath: absolutePath(filePath)))
                } else {
                    throw "Error writing file: \(filePath)"
                }
                if addPodspec,
                   let podSpecJson = podSpecJson,
                   let data = try? JSONSerialization.data(withJSONObject: podSpecJson, options: .prettyPrinted) {
                    try? data.write(to:
                        URL(fileURLWithPath: absolutePath("Pods/\(specification.name)/\(specification.name).json"))
                    )
                }
            }
        }

        if concurrent {
            let dGroup = DispatchGroup()
            specifications.forEach({ specification in
                dGroup.enter()
                DispatchQueue.global().async {
                    do {
                        try compiler(specification)
                    } catch {
                        print("Error generating \(specification.name): \(error)")
                    }
                    dGroup.leave()
                }
            })
            dGroup.wait()
        } else {
            specifications.forEach({ specification in
                do {
                    try compiler(specification)
                } catch {
                    print("Error generating \(specification.name): \(error)")
                }
            })
        }
        if !debug {
            try Data().write(to: URL(fileURLWithPath: absolutePath("Pods/BUILD.bazel")))
        }
    }

    func absolutePath(_ path: String) -> String {
        guard !path.starts(with: "/") else { return path }
        return (src as NSString).appendingPathComponent(path)
    }

    func getJSONPodspec(shell: ShellContext, podspecName: String, path: String) throws -> JSONDict {
        let jsonData: Data
        // Check the path and child paths
        let podspecPath = path
        let currentDirectoryPath = src
        if FileManager.default.fileExists(atPath: "\(podspecPath).json") {
            jsonData = shell.command("/bin/cat", arguments: [podspecPath + ".json"]).standardOutputData
        } else if FileManager.default.fileExists(atPath: podspecPath) {
            // This uses the current environment's cocoapods installation.
            let whichPod = shell.shellOut("which pod").standardOutputAsString
            if whichPod.isEmpty {
                throw "RepoTools requires a cocoapod installation on host"
            }
            let podBin = whichPod.components(separatedBy: "\n")[0]
            let podResult = shell.command(podBin, arguments: ["ipc", "spec", podspecPath])
            guard podResult.terminationStatus == 0 else {
                throw """
                        PodSpec decoding failed \(podResult.terminationStatus)
                        stdout: \(podResult.standardOutputAsString)
                        stderr: \(podResult.standardErrorAsString)
                """
            }
            jsonData = podResult.standardOutputData
        } else {
            throw "Missing podspec ( \(podspecPath) ) inside \(currentDirectoryPath)"
        }

        guard let JSONFile = try? JSONSerialization.jsonObject(with: jsonData, options:
            JSONSerialization.ReadingOptions.allowFragments) as AnyObject,
            let JSONPodspec = JSONFile as? JSONDict
        else {
            throw "Invalid JSON Podspec: (look inside \(currentDirectoryPath))"
        }
        return JSONPodspec
    }
}

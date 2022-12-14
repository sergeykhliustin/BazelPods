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

fileprivate let IGNORE_FILELIST = [
    "build.bazel",
    "build",
    "workspace",
    "workspace.bazel"
]

struct RootCommand: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "Generator",
                                                    abstract: "Generates BUILD files for pods")
    @Argument(help: "Pods.json")
    var podsJson: String

    @Option(name: .long, help: "Sources root where Pods directory located (or renamed by podsRoot)")
    var src: String

    @Option(name: .long, help: "Minimum iOS version to bump old Pods")
    var minIos: String?

    @Option(name: .long, help: "Dependencies prefix")
    var depsPrefix: String = "//Pods"

    @Option(name: .long, help: "Pods root relative to workspace. Used for headers search paths")
    var podsRoot: String = "Pods"

    @Flag(name: .shortAndLong, help: "Packaging pods in dynamic frameworks if possible (same as `use_frameworks!`)")
    var frameworks: Bool = false

    @Flag(name: .shortAndLong, help: "Concurrent mode for generating files faster")
    var concurrent: Bool = false

    @Flag(name: .long, help: "Print BUILD files contents to terminal output")
    var printOutput: Bool = false

    @Flag(name: .long, help: "Debug mode. Files will not be written")
    var debug: Bool = false

    @Flag(name: .shortAndLong, help: "Will add podspec.json to the pod directory. Just for debugging purposes.")
    var addPodspec: Bool = false

    @Option(name: .long, parsing: .upToNextOption, help: "User extra options. Current supported fields are 'sdk_dylibs', 'sdk_frameworks', 'weak_sdk_frameworks'. Format 'SomePod.sdk_dylibs+=something'")
    var userOptions: [String] = []

    func run() throws {
        _ = CrashReporter()
        let data = try NSData(contentsOfFile: absoluteSRCPath(podsJson), options: [])
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let json = try decoder.decode([String: PodConfig].self, from: data as Data)

        let specifications = PodSpecification.resolve(with: json).sorted(by: { $0.name < $1.name })
        let compiler: (PodSpecification) throws -> Void = { specification in
            print("Generating: \(specification.name)" +
                  (specification.subspecs.isEmpty ? "" : " \n\tsubspecs: " +
                   specification.subspecs.joined(separator: " ")))
            let podSpec: PodSpec
            var podSpecJson: JSONDict?
            if specification.podspec.hasSuffix(".json") {
                let jsonData = try NSData(contentsOfFile: absoluteSRCPath(specification.podspec), options: []) as Data
                let jsonFile = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
                guard let jsonPodspec = jsonFile as? JSONDict else {
                    throw "Error parsing podspec at path \(specification.podspec)"
                }
                podSpec = try PodSpec(JSONPodspec: jsonPodspec)
                podSpecJson = jsonPodspec
            } else {
                let jsonPodspec = try getJSONPodspec(shell: SystemShellContext(trace: false),
                                                     podspecName: specification.name,
                                                     path: absoluteSRCPath(specification.podspec))
                podSpec = try PodSpec(JSONPodspec: jsonPodspec)
                podSpecJson = jsonPodspec
            }

            // Consider adding a split here to split out sublibs
            let buildOptions = BasicBuildOptions(podName: specification.name,
                                                 subspecs: specification.subspecs,
                                                 podspecPath: specification.podspec,
                                                 sourcePath: src,
                                                 userOptions: userOptions,
                                                 minIosPlatform: minIos,
                                                 depsPrefix: depsPrefix,
                                                 podsRoot: podsRoot,
                                                 dynamicFrameworks: frameworks)
            let starlarkString = PodBuildFile
                .with(podSpec: podSpec, buildOptions: buildOptions)
                .compile()

            if printOutput {
                print(starlarkString)
            }
            if !debug {
                if var developmentPath = specification.developmentPath {
                    try? FileManager.default.removeItem(atPath: absoluteSRCPath("Pods/\(specification.name)"))
                    try? FileManager.default.createDirectory(atPath: absoluteSRCPath("Pods/\(specification.name)"),
                                                             withIntermediateDirectories: false)
                    if developmentPath.lastPath.hasSuffix("podspec") || developmentPath.lastPath.hasSuffix("podspec.json") {
                        developmentPath = developmentPath.deletingLastPath
                    }

                    let contents = (try? FileManager.default.contentsOfDirectory(atPath: absolutePath(developmentPath, base: src))) ?? []
                    contents.forEach({ file in
                        guard !file.starts(with: ".") else { return }
                        guard !file.starts(with: "bazel-") else { return }
                        guard !IGNORE_FILELIST.contains(file.lowercased()) else { return }
                        let sourcePath = absolutePath(file, base: developmentPath)
                        let symlinkPath = absoluteSRCPath("Pods/\(specification.name)/\(file)")
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
                    try data.write(to: URL(fileURLWithPath: absoluteSRCPath(filePath)))
                } else {
                    throw "Error writing file: \(filePath)"
                }
                if addPodspec,
                   let podSpecJson = podSpecJson,
                   let data = try? JSONSerialization.data(withJSONObject: podSpecJson, options: .prettyPrinted) {
                    try? data.write(to:
                        URL(fileURLWithPath: absoluteSRCPath("Pods/\(specification.name)/\(specification.name).json"))
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
            try Data().write(to: URL(fileURLWithPath: absoluteSRCPath("Pods/BUILD.bazel")))
        }
    }

    func absoluteSRCPath(_ path: String) -> String {
        return absolutePath(path, base: src)
    }

    func absolutePath(_ path: String, base: String) -> String {
        guard !path.starts(with: "/") else { return path }
        return (base as NSString).appendingPathComponent(path)
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

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

private let IGNORE_FILELIST = [
    "build.bazel",
    "build",
    "workspace",
    "workspace.bazel"
]

enum ColorMode: String, ExpressibleByArgument {
    case auto
    case yes
    case no
}

extension LogLevel: ExpressibleByArgument {}
extension Platform: ExpressibleByArgument {}
extension PatchType: ExpressibleByArgument {}

struct RootCommand: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "Generator",
                                                    abstract: "Generates BUILD files for pods")
    @Option(name: .long, help: "Sources root where Pods directory located (or renamed by podsRoot)")
    var src: String

    @Option(help: "Pods.json")
    var podsJson: String = "Pods/Pods.json"

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

    @Flag(name: .long, help: "Print BUILD files contents to terminal output")
    var printOutput: Bool = false

    @Flag(name: .long, help: "Dry run. Files will not be written")
    var dryRun: Bool = false

    @Flag(name: .shortAndLong, help: "Print diff between previous and new generated BUILD files")
    var diff: Bool = false

    @Flag(name: .shortAndLong, help: "Will add podspec.json to the pod directory. Just for debugging purposes.")
    var addPodspec: Bool = false

    @Option(help: "Logs color (auto|yes|no)")
    var color: ColorMode = .auto

    @Option(help: "Log level (\(LogLevel.allCases.map({ $0.rawValue }).joined(separator: "|")))")
    var logLevel: LogLevel = .info

    func run() throws {
        _ = CrashReporter()
        configureLogger(nil)
        let data = try NSData(contentsOfFile: absoluteSRCPath(podsJson), options: [])
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let json = try decoder.decode([String: PodConfig].self, from: data as Data)

        let userOptions = userOptions
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            .filter({ !$0.isEmpty })
            .compactMap({ UserOption($0) })

        let specifications = PodSpecification.resolve(with: json).sorted(by: { $0.name < $1.name })

        if !noConcurrency {
            let dGroup = DispatchGroup()
            specifications.forEach({ specification in
                dGroup.enter()
                DispatchQueue.global().async {
                    configureLogger(specification.name)
                    do {
                        try process(specification: specification, userOptions: userOptions)
                    } catch {
                        log_error(error)
                    }
                    dGroup.leave()
                }
            })
            dGroup.wait()
        } else {
            specifications.forEach({ specification in
                configureLogger(specification.name)
                do {
                    try process(specification: specification, userOptions: userOptions)
                } catch {
                    log_error(error)
                }
            })
        }
        if !dryRun {
            try Data().write(to: URL(fileURLWithPath: absoluteSRCPath("Pods/BUILD.bazel")))
        }
    }

    func process(specification: PodSpecification, userOptions: [UserOption]) throws {
        logger.log_info("Generating..." + (specification.subspecs.isEmpty ? "" : " subspecs: " +
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
                                             sourcePath: src,
                                             platforms: platforms,
                                             patches: patches,
                                             userOptions: userOptions,
                                             minIosPlatform: minIos,
                                             depsPrefix: depsPrefix,
                                             podsRoot: podsRoot,
                                             useFrameworks: frameworks,
                                             noConcurrency: noConcurrency)
        let starlarkString = PodBuildFile
            .with(podSpec: podSpec, buildOptions: buildOptions)
            .compile()

        let filePath = "Pods/\(specification.name)/BUILD.bazel"

        if printOutput {
            print(starlarkString)
        }

        processDiff(filePath: filePath, string: starlarkString)

        guard !dryRun else { return }

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
                    log_error("creating symlink: \(error)")
                }
            })
        }

        if let data = starlarkString.data(using: .utf8) {
            try data.write(to: URL(fileURLWithPath: absoluteSRCPath(filePath)))
        } else {
            throw "Error writing file: \(filePath)"
        }
        if addPodspec,
           let podSpecJson = podSpecJson,
           let data = try? JSONSerialization.data(withJSONObject: podSpecJson, options: .prettyPrinted) {
            try? data.write(to: URL(fileURLWithPath: absoluteSRCPath("Pods/\(specification.name)/\(specification.name).json")))
        }
    }

    func processDiff(filePath: String, string: String) {
        guard diff else { return }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: absoluteSRCPath(filePath))) else { return }
        guard let prevString = String(data: data, encoding: .utf8) else { return }

        let str1Lines = string.components(separatedBy: .newlines)
        let str2Lines = prevString.components(separatedBy: .newlines)
        let lineChanges = str1Lines.difference(from: str2Lines)
            .sorted(by: { diff1, diff2 in
                switch (diff1, diff2) {
                case (.insert(let offset1, _, _), .insert(let offset2, _, _)):
                    return offset1 < offset2
                case (.remove(let offset1, _, _), .remove(let offset2, _, _)):
                    return offset1 < offset2
                case (.insert(let offset1, _, _), .remove(let offset2, _, _)):
                    return offset1 < offset2
                case (.remove(let offset1, _, _), .insert(let offset2, _, _)):
                    return offset1 < offset2
                }
            })
        var output = ""

        for change in lineChanges {
            switch change {
            case .remove(let offset, let element, _):
                output += "-\(offset): \(element)\n"
            case .insert(let offset, let element, _):
                output += "+\(offset): \(element)\n"
            }
        }
        guard !output.isEmpty else { return }
        output = "Found BUILD.bazel diff\n" + output
        log_info(output)
    }

    func configureLogger(_ prefix: String?) {
        switch color {
        case .auto:
            logger.colors = getenv("TERM") != nil
        case .yes:
            logger.colors = true
        case .no:
            logger.colors = false
        }
        logger.prefix = prefix
        logger.level = logLevel
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

//
//  MissingSdksPatch.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 22.02.2023.
//

import Foundation

struct MissingSdksPatch: Patch {
    private let commentsRegexStr = #"(\/\*.*?\*\/|\/\/.*)"#
    private let swiftImportRegexStr = #"import\s+\w+(\.\w+)*"#
    private let objcLegacyImportRegexStr = #"#import\s*<\w+\/"#
    private let objcModuleImportRegexStr = #"@import\s+\w+;"#
    private let options: BuildOptions
    private let platform: Platform

    init(_ options: BuildOptions, platform: Platform) {
        self.options = options
        self.platform = platform
    }

    func run(base: inout BaseAnalyzer.Result,
             sources: inout SourcesAnalyzer.Result,
             resources: inout ResourcesAnalyzer.Result,
             sdkDeps: inout SdkDependenciesAnalyzer.Result,
             vendoredDeps: inout VendoredDependenciesAnalyzer.Result,
             podDeps: inout PodDependenciesAnalyzer.Result,
             buildSettings: inout BuildSettingsAnalyzer.Result) {
        guard platform == .ios else {
            log_debug("Wrong platform \(platform). Only ios currently supported")
            return
        }
        var imports: Set<String> = []
        let allSourcePaths = sources.sourceFiles.sourcesOnDisk(options)
            .union(sources.publicHeaders.sourcesOnDisk(options))
            .union(sources.privateHeaders.sourcesOnDisk(options))
        for file in allSourcePaths {
            do {
                var string = try NSString(contentsOfFile: file, encoding: NSUTF8StringEncoding) as String
                let commentsRegex = try NSRegularExpression(pattern: commentsRegexStr)
                string = commentsRegex.stringByReplacingMatches(in: string, range: NSRange(location: 0, length: string.count), withTemplate: "")

                let swiftRegex = try NSRegularExpression(pattern: swiftImportRegexStr)
                var matches = Set<String>(swiftRegex.matches(in: string))
                for match in matches {
                    let framework = match.deletingPrefix("import").trimmingCharacters(in: .whitespacesAndNewlines)
                    imports.insert(framework)
                }

                let objcLegacyRegex = try NSRegularExpression(pattern: objcLegacyImportRegexStr)
                matches = Set<String>(objcLegacyRegex.matches(in: string))
                for match in matches {
                    let framework = match.deletingPrefix("#import")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .deletingPrefix("<")
                        .deletingSuffix("/")
                    imports.insert(framework)
                }

                let objcModulesRegex = try NSRegularExpression(pattern: objcModuleImportRegexStr)
                matches = Set<String>(objcModulesRegex.matches(in: string))
                for match in matches {
                    let framework = match.deletingPrefix("@import")
                        .deletingSuffix(";")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    imports.insert(framework)
                }
            } catch {
                log_debug(error)
            }
        }
        imports = imports
            .intersection(AllSDKFrameworks.ios)
            .filter({ !sdkDeps.sdkFrameworks.contains($0) && !sdkDeps.weakSdkFrameworks.contains($0) })
        if !imports.isEmpty {
            log_debug("Found missing sdks: \(imports.joined(separator: ", "))")
            sdkDeps.sdkFrameworks.append(contentsOf: imports.sorted())
        }
    }
}

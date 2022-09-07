//
//  RuleUtils.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 9/20/2018.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

import Foundation

/// Extract files from a source file pattern.
func extractFiles(fromPattern patternSet: AttrSet<Set<String>>,
                  includingFileTypes: Set<String>,
                  usePrefix: Bool = false,
                  options: BuildOptions) -> AttrSet<Set<String>> {
    let sourcePrefix = usePrefix ? getSourcePatternPrefix(options: options) : ""
    return patternSet.map { (patterns: Set<String>) -> Set<String> in
        let result = patterns.flatMap { (p: String) -> [String] in
            pattern(fromPattern: sourcePrefix + p, includingFileTypes:
                        includingFileTypes)
        }
        return Set(result)
    }
}

func extractFiles(fromPattern patternSet: AttrSet<[String]>,
                  includingFileTypes: Set<String>,
                  usePrefix: Bool = false,
                  options: BuildOptions) -> AttrSet<[String]> {
    let sourcePrefix = usePrefix ? getSourcePatternPrefix(options: options) : ""
    return patternSet.map { (patterns: [String]) -> [String] in
        let result = patterns.flatMap { (p: String) -> [String] in
            pattern(fromPattern: sourcePrefix + p, includingFileTypes:
                        includingFileTypes)
        }
        return result
    }
}

public func extractFiles(fromPattern patternSet: [String],
                         includingFileTypes: Set<String>,
                         usePrefix: Bool = true,
                         options: BuildOptions) -> [String] {
    let sourcePrefix = usePrefix ? getSourcePatternPrefix(options: options) : ""
    return patternSet.flatMap { (p: String) -> [String] in
            pattern(fromPattern: sourcePrefix + p, includingFileTypes:
                    includingFileTypes)
        }
}

let ObjcLikeFileTypes = Set([".m", ".c", ".s", ".S"])
let CppLikeFileTypes  = Set([".mm", ".cpp", ".cxx", ".cc"])
let SwiftLikeFileTypes  = Set([".swift"])
let HeaderFileTypes = Set([".h", ".hpp", ".hxx"])
let AnyFileTypes = ObjcLikeFileTypes
    .union(CppLikeFileTypes)
    .union(SwiftLikeFileTypes)
    .union(HeaderFileTypes)

public func getNamePrefix(options: BuildOptions) -> String {
    if options.podTargetSrcRoot.split(separator: "/").count > 2 {
        return options.podName + "_"
    }
    return ""
}

public func getSourcePatternPrefix(options: BuildOptions) -> String {
    let parts = options.podTargetSrcRoot.split(separator: "/")
    if options.podTargetSrcRoot ==  "." || parts.count < 2 {
        return ""
    }
    let sourcePrefix = String(parts[2..<parts.count].joined(separator: "/"))
    if sourcePrefix != "" {
        return sourcePrefix + "/"
    }
    return ""
}

/// Get a dependency name from a name in accordance with
/// CocoaPods dependency naming ( slashes )
/// Versions are ignored!
/// When a given dependency is locally spec'ed, it should
/// Match the PodName i.e. PINCache/Core
public func getDependencyName(podDepName: String, podName: String, options: BuildOptions) -> String {
    let results = podDepName.components(separatedBy: "/")
    if results.count > 1 && results[0] == podName {
        // This is a local subspec reference
        let join = results[1 ... results.count - 1].joined(separator: "/")
        return ":\(getNamePrefix(options: options) + bazelLabel(fromString: join))"
    } else {
        if results.count > 1 {
            return options.getRulePrefix(name: results[0])
        } else {
            // This is a reference to another pod library
            return options.getRulePrefix(name:
                    bazelLabel(fromString: results[0]))
        }
    }
}

/// Convert a string to a Bazel label conventional string
public func bazelLabel(fromString string: String) -> String {
	return string.replacingOccurrences(of: "/", with: "_")
				 .replacingOccurrences(of: "+", with: "_")
}

public func replacePodsEnvVars(_ value: String, options: BuildOptions) -> String {
    let podDir = options.podsRoot
    let targetDir = options.podTargetSrcRoot
    return value
        .replacingOccurrences(of: "$(inherited)", with: "")
        .replacingOccurrences(of: "$(PODS_ROOT)", with: podDir)
        .replacingOccurrences(of: "${PODS_ROOT}", with: podDir)
        .replacingOccurrences(of: "$(PODS_TARGET_SRCROOT)", with: targetDir)
        .replacingOccurrences(of: "${PODS_TARGET_SRCROOT}", with: targetDir)
}

public func xcconfigSettingToList(_ value: String) -> [String] {
    return value
        .components(separatedBy: "=\"")
        .map {
            let components = $0.components(separatedBy: "\"")
            guard components.count == 2 else {
                return $0
            }
            let modifiedValue = [
                components.first?.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "",
                components.dropFirst().joined()
            ].joined(separator: "\\\"")
            return modifiedValue
        }
        .joined(separator: "=\\\"")
        .components(separatedBy: .whitespaces)
        .map { $0.removingPercentEncoding ?? "" }
        .filter({ $0 != "$(inherited)"})
        .filter({ !$0.isEmpty })
}

public func isDynamicFramework(_ framework: String, options: BuildOptions) -> Bool {
    let frameworkPath = URL(fileURLWithPath: framework, relativeTo: URL(fileURLWithPath: options.podTargetAbsoluteRoot))
    let frameworkName = frameworkPath.deletingPathExtension().lastPathComponent
    let executablePath = frameworkPath.appendingPathComponent(frameworkName)
    // TODO: Find proper way
    let output = SystemShellContext().command("/usr/bin/file", arguments: [executablePath.path]).standardOutputAsString
    return output.contains("dynamically")
}

public func frameworkArchs(_ framework: String, options: BuildOptions) -> [String] {
    let frameworkPath = URL(fileURLWithPath: framework, relativeTo: URL(fileURLWithPath: options.podTargetAbsoluteRoot))
    let frameworkName = frameworkPath.deletingPathExtension().lastPathComponent

    let executablePath = frameworkPath.appendingPathComponent(frameworkName)
    let archs = SystemShellContext().command("/usr/bin/lipo",
                                             arguments: ["-archs", executablePath.path])
        .standardOutputAsString
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .components(separatedBy: " ")
    return archs
}

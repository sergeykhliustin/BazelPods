//
//  RuleUtils.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 9/20/2018.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

public enum BazelSourceLibType {
    case objc
    case swift
    case cpp

    func getLibNameSuffix() -> String {
        switch self {
        case .objc:
            return "_objc"
        case .cpp:
            return "_cxx"
        case .swift:
            return "_swift"
        }
    }
}

/// Extract files from a source file pattern.
func extractFiles(fromPattern patternSet: AttrSet<[String]>,
                         includingFileTypes: Set<String>,
                         usePrefix: Bool = true,
                         options: BuildOptions) ->
AttrSet<[String]> {
    let sourcePrefix = usePrefix ? getSourcePatternPrefix(options: options) : ""
    return patternSet.map {
        (patterns: [String]) -> [String] in
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

public func getRulePrefix(name: String) -> String {
    return "//Pods/\(name)"
}

public func getPodBaseDir() -> String {
    return "Pods"
}

/// We need to hardcode a copt to the $(GENDIR) for simplicity.
/// Expansion of $(location //target) is not supported in known Xcode generators
public func getGenfileOutputBaseDir(options: BuildOptions) -> String {
    let basePath = "Pods"
    let podName = options.podName
    let parts = options.path.split(separator: "/")
    if options.path ==  "." || parts.count < 2 {
        return "\(basePath)/\(podName)"
    }

    return String(parts[0..<2].joined(separator: "/"))
}

public func getNamePrefix(options: BuildOptions) -> String {
    if options.path.split(separator: "/").count > 2 {
        return options.podName + "_"
    }
    return ""
}

public func getSourcePatternPrefix(options: BuildOptions) -> String {
    let parts = options.path.split(separator: "/")
    if options.path ==  "." || parts.count < 2 {
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
public func getDependencyName(options: BuildOptions, podDepName: String, podName: String) -> String  {
    let results = podDepName.components(separatedBy: "/")
    if results.count > 1 && results[0] == podName {
        // This is a local subspec reference
        let join = results[1 ... results.count - 1].joined(separator: "/")
        return ":\(getNamePrefix(options: options) + bazelLabel(fromString: join))"
    } else {
        if results.count > 1 {
            return getRulePrefix(name: results[0])
        } else {
            // This is a reference to another pod library
            return getRulePrefix(name:
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
    let podDir = options.podBaseDir
    let targetDir = options.genfileOutputBaseDir
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

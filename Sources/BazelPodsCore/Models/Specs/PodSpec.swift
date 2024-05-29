//
//  PodSpec.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/14/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation

/*
 Cocoapods Podspec Specification (as of 4/25/17)
 https://guides.cocoapods.org/syntax/podspec.html#specification

 Root Specification:
 name R
 version R
 cocoapods_version
 authors R
 social_media_url
 license R
 homepage R
 source R
 summary R
 description
 screenshots
 documentation_url
 prepare_command
 deprecated
 deprecated_in_favor_of
 A ‘root’ specification stores the information about the specific version of a library.
 The attributes in this group can only be written to on the ‘root’ specification, not on the ‘sub-specifications’.

 ---

 Platform:
 platform
 deployment_target

 A specification should indicate the platform and the correspondent deployment targets on which the library is supported
 If not defined in a subspec the attributes of this group inherit the value of the parent."

 ---

 Build settings:
 dependency
 requires_arc M
 frameworks M
 weak_frameworks M
 libraries M
 compiler_flags M
 pod_target_xcconfig M
 user_target_xcconfig M
 prefix_header_contents M
 prefix_header_file M
 module_name
 header_dir M
 header_mappings_dir M

 ---
 File Patterns (Glob-able) - All MultiPlatform
 source_files
 public_header_files
 private_header_files
 vendored_frameworks
 vendored_libraries
 resource_bundles
 resources
 exclude_files
 preserve_paths
 module_map

 ---

 Subspecs:
 subspec
 default_subspecs

 On one side, a specification automatically inherits as a dependency all it children ‘sub-specifications’ (unless a default subspec is specified).
 On the other side, a ‘sub-specification’ inherits the value of the attributes of the parents so common values for attributes can be specified in the ancestors.

 ---

 Multi-Platform support:
 ios
 osx
 tvos
 watchos

 A specification can store values which are specific to only one platform.
 For example one might want to store resources which are specific to only iOS projects.
 spec.resources = 'Resources /**/ *.png'
 spec.ios.resources = 'Resources_ios /**/ *.png'

 */

enum PodSpecField: String {
    case prefixHeaderFile = "prefix_header_file"
    case prefixHeaderContents = "prefix_header_contents"
    case preservePaths = "preserve_paths"
    case subspecs
    case source
    case license
    case podTargetXcconfig = "pod_target_xcconfig"
    case userTargetXcconfig = "user_target_xcconfig"
    case xcconfig // Legacy
    case headerDirectory = "header_dir"
    case defaultSubspecs = "default_subspecs"
    case testspecs
    case appspecs
}

public final class PodSpec: PodSpecRepresentable {
    let name: String
    let ios: PodSpec?
    let osx: PodSpec?
    let tvos: PodSpec?
    let watchos: PodSpec?

    let version: String
    let moduleName: String?
    let platforms: [String: String]
    let swiftVersions: [String]?

    let sourceFiles: [String]
    let excludeFiles: [String]
    let publicHeaders: [String]
    let privateHeaders: [String]
    // requiresArc can be a bool
    // or it could be a list of pattern
    // or it could be omitted (in which case we need to fallback)
    let requiresArc: Either<Bool, [String]>?
    let staticFramework: Bool

    let libraries: [String]
    let frameworks: [String]
    let weakFrameworks: [String]

    let resourceBundles: [String: [String]]
    let resources: [String]

    let dependencies: [String]

    let podTargetXcconfig: [String: String]
    let userTargetXcconfig: [String: String]
    let xcconfig: [String: String]
    let compilerFlags: [String]

    let subspecs: [PodSpec]
    let source: PodSpecSource?
    let license: PodSpecLicense
    let defaultSubspecs: [String]

    let headerDirectory: String?

    // lib/cocoapods/installer/xcode/pods_project_generator/pod_target_installer.rb:170
    let prefixHeaderFile: Either<Bool, String>?
    let prefixHeaderContents: String?

    let preservePaths: [String]

    let vendoredFrameworks: [String]
    let vendoredLibraries: [String]

    let infoPlist: [String: Any]?

    let prepareCommand = ""

    let testspecs: [TestSpec]
    let appspecs: [AppSpec]

    public convenience init(JSONPodspec json: JSONDict) throws {
        let version = (json["version"] as? String)?.appleCompatibleVersion ?? "1.0"
        try self.init(JSONPodspec: json, version: version)
    }

    public init(JSONPodspec json: JSONDict, version: String) throws {
        self.version = version

        let fieldMap: [PodSpecField: Any] = Dictionary(tuples: json.compactMap { k, v in
            guard let field = PodSpecField.init(rawValue: k) else {
                return nil
            }
            return .some((field, v))
        })

        // BaseRepresentable
        name = Self.name(json: json)
        ios = Self.ios(json: json, version: version)
        osx = Self.osx(json: json, version: version)
        tvos = Self.tvos(json: json, version: version)
        watchos = Self.watchos(json: json, version: version)

        // BaseInfoRepresentable
        moduleName = Self.moduleName(json: json)
        platforms = Self.platforms(json: json)
        swiftVersions = Self.swiftVersions(json: json)

        // SourceFilesRepresentable
        sourceFiles = Self.sourceFiles(json: json)
        excludeFiles = Self.excludeFiles(json: json)
        publicHeaders = Self.publicHeaders(json: json)
        privateHeaders = Self.privateHeaders(json: json)
        requiresArc = Self.requiresArc(json: json)
        staticFramework = Self.staticFramework(json: json)

        // ResourceRepresentable
        resourceBundles = Self.resourceBundles(json: json)
        resources = Self.resources(json: json)

        // SdkDependenciesRepresentable
        libraries = Self.libraries(json: json)
        frameworks = Self.frameworks(json: json)
        weakFrameworks = Self.weakFrameworks(json: json)

        // PodDependencyRepresentable
        dependencies = Self.dependencies(json: json)

        // XCConfigRepresentable
        xcconfig = Self.xcconfig(json: json)
        podTargetXcconfig = Self.podTargetXcconfig(json: json)
        userTargetXcconfig = Self.userTargetXcconfig(json: json)
        compilerFlags = Self.compilerFlags(json: json)

        // VendoredDependenciesRepresentable
        vendoredLibraries = Self.vendoredLibraries(json: json)
        vendoredFrameworks = Self.vendoredFrameworks(json: json)

        // InfoPlistRepresentable
        infoPlist = Self.infoPlist(json: json)

        prefixHeaderFile  = (fieldMap[.prefixHeaderFile] as? Bool).map { .left($0) } ?? // try a bool
	        (fieldMap[.prefixHeaderFile] as? String).map { .right($0) } // try a string

        prefixHeaderContents = fieldMap[.prefixHeaderContents] as? String

        preservePaths = strings(fromJSON: fieldMap[.preservePaths])

        defaultSubspecs = strings(fromJSON: fieldMap[.defaultSubspecs])

        headerDirectory = fieldMap[.headerDirectory] as? String

        if let JSONPodSubspecs = fieldMap[.subspecs] as? [JSONDict] {
            subspecs = try JSONPodSubspecs.map { try PodSpec(JSONPodspec: $0) }
        } else {
            subspecs = []
        }

        if let JSONSource = fieldMap[.source] as? JSONDict {
            source = PodSpecSource.source(fromDict: JSONSource)
        } else {
            source = nil
        }

        license = PodSpecLicense.license(fromJSON: fieldMap[.license])

        self.testspecs = (fieldMap[.testspecs] as? [JSONDict])?.compactMap({
            do {
                return try TestSpec(JSONPodspec: $0, version: version)
            } catch {
                log_debug(error)
            }
            return nil
        }) ?? []
        self.appspecs = (fieldMap[.appspecs] as? [JSONDict])?.compactMap({
            do {
                return try AppSpec(JSONPodspec: $0, version: version)
            } catch {
                log_debug(error)
            }
            return nil
        }) ?? []
    }

    func allSubspecs(_ isSubspec: Bool = false) -> [PodSpec] {
        return (isSubspec ? [self] : []) + self.subspecs.reduce([PodSpec]()) {
            return $0 + $1.allSubspecs(true)
        }
    }

    public func selectedSubspecs(subspecs: [String]) -> [PodSpec] {
        let defaultSubspecs = Set(subspecs.isEmpty ? self.defaultSubspecs : subspecs)
        let allSubspecs = allSubspecs()
        guard !defaultSubspecs.isEmpty else {
            return allSubspecs
        }
        return allSubspecs.filter { defaultSubspecs.contains($0.name) }
    }

    public func selectedTestspecs(subspecs: [String]) -> [TestSpec] {
        return testspecs.filter { subspecs.contains($0.name) }
    }

    public func selectedAppspecs(subspecs: [String]) -> [AppSpec] {
        var requiredAppspecs: Set<String> = []
        selectedTestspecs(subspecs: subspecs).forEach({
            if let appHostName = $0.appHostName, $0.requiresAppHost {
                requiredAppspecs.insert(appHostName)
            }
        })
        subspecs.forEach({ requiredAppspecs.insert($0) })
        return appspecs.filter { requiredAppspecs.contains($0.name) }
    }
}

// The source component of a PodSpec
// @note currently only git is supported
enum PodSpecSource {
    case git(url: URL, tag: String?, commit: String?)
    case http(url: URL)

    static func source(fromDict dict: JSONDict) -> PodSpecSource {
        if let gitURLString: String = try? extractValue(fromJSON: dict["git"]) {
            guard let gitURL = URL(string: gitURLString) else {
                fatalError("Invalid source URL for Git: \(gitURLString)")
            }
            let tag: String? = try? extractValue(fromJSON: dict["tag"])
            let commit: String? = try? extractValue(fromJSON: dict["commit"])
            return .git(url: gitURL, tag: tag, commit: commit)
        } else if let httpURLString: String = try? extractValue(fromJSON: dict["http"]) {
            guard let httpURL = URL(string: httpURLString) else {
                fatalError("Invalid source URL for HTTP: \(httpURLString)")
            }
            return .http(url: httpURL)
        } else {
            fatalError("Unsupported source for PodSpec - \(dict)")
        }
    }
}

struct PodSpecLicense {
    /// The type of the license.
    /// @note it's primarily used for the UI
    let type: String?

    /// A license can either be a file or a text license
    /// If there is no explict license, the LICENSE(.*) is implicitly
    /// used
    let text: String?
    let file: String?

    static func license(fromJSON value: Any?) -> PodSpecLicense {
        if let licenseJSON = value as? JSONDict {
            return PodSpecLicense(
                    type: try? extractValue(fromJSON: licenseJSON["type"]),
                    text: try? extractValue(fromJSON: licenseJSON["text"]),
                    file: try? extractValue(fromJSON: licenseJSON["file"])
                    )
        }
        if let licenseString = value as? String {
            return PodSpecLicense(type: licenseString, text: nil, file: nil)
        }
        return PodSpecLicense(type: nil, text: nil, file: nil)
    }
}

// MARK: - JSON Value Extraction

public typealias JSONDict = [String: Any]

enum JSONError: Error {
    case unexpectedValueError
}

func extractValue<T>(fromJSON JSON: Any?) throws -> T {
    if let value = JSON as? T {
        return value
    }
    throw JSONError.unexpectedValueError
}

func extractValue<T>(fromJSON JSON: Any?, default: T) -> T {
    if let value = JSON as? T {
        return value
    } else {
        return `default`
    }
}

// Pods intermixes arrays and strings all over
// Coerce to a more sane type, since we don't care about the
// original input
func strings(fromJSON JSONValue: Any? = nil) -> [String] {
    if let str = JSONValue as? String {
        return [str]
    }
    if let array = JSONValue as? [String] {
        return array
    }
    return [String]()
}

func stringsStrict(fromJSON JSONValue: Any? = nil) -> [String]? {
    if let str = JSONValue as? String {
        return [str]
    }
    if let array = JSONValue as? [String] {
        return array
    }
    return nil
}

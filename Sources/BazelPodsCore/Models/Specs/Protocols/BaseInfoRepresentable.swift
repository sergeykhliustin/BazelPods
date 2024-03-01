//
//  BaseInfoRepresentable.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 02.02.2024.
//

import Foundation

protocol BaseInfoRepresentable: BaseRepresentable {
    var version: String { get }
    var moduleName: String? { get }
    var platforms: [String: String] { get }
    var swiftVersions: [String]? { get }
}

private enum Keys: String {
    case module_name
    case platforms
    case swift_version
    case swift_versions
}

extension BaseInfoRepresentable {
    static func moduleName(json: JSONDict) -> String? {
        return json[Keys.module_name.rawValue] as? String
    }

    static func platforms(json: JSONDict) -> [String: String] {
        return extractValue(fromJSON: json[Keys.platforms.rawValue], default: [:])
    }

    static func swiftVersions(json: JSONDict) -> [String]? {
        var resultSwiftVersions = Set<String>()
        if let swiftVersions = json[Keys.swift_versions.rawValue] as? String {
            resultSwiftVersions.insert(swiftVersions)
        } else if let swiftVersions = json[Keys.swift_versions.rawValue] as? [String] {
            swiftVersions.forEach {
                resultSwiftVersions.insert($0)
            }
        }
        if let swiftVersion = json[Keys.swift_version.rawValue] as? String {
            resultSwiftVersions.insert(swiftVersion)
        }
        return !resultSwiftVersions.isEmpty ? Array(resultSwiftVersions) : nil
    }
}

extension BaseInfoRepresentable {
    func platformRepresentable(_ platform: Platform) -> Self? {
        switch platform {
        case .ios:
            return ios
        case .osx:
            return osx
        case .tvos:
            return tvos
        case .watchos:
            return watchos
        }
    }

    func resolveModuleName(_ platform: Platform, options: BuildOptions) -> String {
        if let specModuleName = moduleName ?? platformRepresentable(platform)?.moduleName {
            return specModuleName
        } else if let buildSettings = self as? XCConfigRepresentable, let moduleName = buildSettings.moduleName {
            return moduleName
        } else if let testSpec = self as? TestSpecRepresentable {
            return [options.podName, testSpec.testType.rawValue.capitalized, name].joined(separator: "_")
        } else {
            return name.replacingOccurrences(of: "-", with: "_")
        }
    }
}

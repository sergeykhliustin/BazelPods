//
//  BaseAnalyzer.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 05.02.2023.
//

import Foundation

public struct BaseAnalyzer {
    public struct Result {
        let name: String
        let version: String
        let moduleName: String
        let platforms: [String: String]
        let swiftVersion: String?
    }

    private let platform: Platform
    private let spec: PodSpec
    private let subspecs: [PodSpec]
    private let options: BuildOptions

    public init(platform: Platform,
                spec: PodSpec,
                subspecs: [PodSpec],
                options: BuildOptions) {
        self.platform = platform
        self.spec = spec
        self.subspecs = subspecs
        self.options = options
    }

    public func run() throws -> Result {
        let name = spec.name
        let version = spec.version ?? "1.0"
        let platformVersion = try resolvePlatformVersion(platform)
        let moduleName: String
        if let specModuleName = spec.moduleName ?? spec.platformRepresentable(platform)?.moduleName {
            moduleName = specModuleName
        } else {
            moduleName = name.replacingOccurrences(of: "-", with: "_")
        }
        let platforms = [platform.rawValue: platformVersion]
        let swiftVersion: String?
        if let versions = spec.attr(\.swiftVersions).platform(platform)??.compactMap({ Double($0) }) {
            if versions.contains(where: { $0 >= 5.0 }) {
                swiftVersion = "5"
            } else if versions.contains(where: { $0 >= 4.2 }) {
                swiftVersion = "4.2"
            } else if !versions.isEmpty {
                swiftVersion = "4"
            } else {
                swiftVersion = nil
            }
        } else {
            swiftVersion = nil
        }
        return Result(name: name,
                      version: version,
                      moduleName: moduleName,
                      platforms: platforms,
                      swiftVersion: swiftVersion)
    }

    private func resolvePlatformVersion(_ platform: Platform) throws -> String {
        let platforms = spec.platforms
        let defaultVersion = options.defaultVersion(for: platform)
        // Assume that if no platforms are specified, it supports any.
        guard
            !platforms.isEmpty
        else {
            return defaultVersion
        }
        guard
            let platformVersion = platforms[platform.rawValue]
        else {
            throw "Unsupported platform \(platform.rawValue)"
        }
        return [platformVersion, defaultVersion]
            .max(by: { $0.compareVersion($1) == .orderedAscending }) ?? defaultVersion
    }
}

//
//  BaseAnalyzer.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 05.02.2023.
//

import Foundation

struct BaseAnalyzer<S: BaseInfoRepresentable> {
    struct Result {
        let name: String
        let version: String
        let moduleName: String
        let platforms: [String: String]
        let minimumOsVersion: String
        let swiftVersion: String?
    }

    private let platform: Platform
    private let spec: S
    private let subspecs: [S]
    private let options: BuildOptions

    init(platform: Platform,
         spec: S,
         subspecs: [S],
         options: BuildOptions) {
        self.platform = platform
        self.spec = spec
        self.subspecs = subspecs
        self.options = options
    }

    public func run() throws -> Result {
        let name = spec.name
        let version = spec.version
        let platformVersion = try resolvePlatformVersion(platform)
        let moduleName: String = spec.resolveModuleName(platform, options: options)
        let platforms = [platform.bazelKey: platformVersion]
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
                      minimumOsVersion: platformVersion,
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

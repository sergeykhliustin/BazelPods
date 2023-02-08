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

    public var result: Result {
        return run()
    }

    private func run() -> Result {
        let name = spec.name
        let version = spec.version ?? "1.0"
        let moduleName: String
        if let specModuleName = spec.moduleName ?? spec.platformRepresentable(platform)?.moduleName {
            moduleName = specModuleName
        } else {
            moduleName = name.replacingOccurrences(of: "-", with: "_")
        }
        let platformVersion = [
            spec.platforms[platform.rawValue],
            options.defaultVersion(for: platform)
        ]
            .compactMap({ $0 })
            .max(by: { $0.compareVersion($1) == .orderedAscending }) ?? ""
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
}

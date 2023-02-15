//
//  BuildOptions.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 3/25/2020.
//  Copyright © 2020 Pinterest Inc. All rights reserved.

import Foundation

public enum Platform: String {
    case ios
    case osx
    case tvos
    case watchos
}

extension Platform {
    var supportedArchs: [Arch] {
        switch self {
        case .ios:
            return [
                .ios_armv7,
                .ios_arm64,
                .ios_arm64e,
                .ios_sim_arm64,
                .ios_i386,
                .ios_x86_64
            ]
        default:
            return [] // TODO: Platforms support
        }
    }
}

public protocol BuildOptions {
    var podName: String { get }
    var subspecs: [String] { get }
    var sourcePath: String { get }
    var platforms: [Platform] { get }
    var minIosPlatform: String { get }
    var depsPrefix: String { get }
    var podsRoot: String { get }
    var useFrameworks: Bool { get }
    var userOptions: [UserOption] { get }
    var podTargetSrcRoot: String { get }
    var podTargetAbsoluteRoot: String { get }
}

extension BuildOptions {
    public static func defaultVersion(for platform: Platform) -> String {
        switch platform {
        case .ios:
            return "13.0"
        case .osx:
            return "10.13"
        case .tvos:
            return "13.0"
        case .watchos:
            return "6.0"
        }
    }
    func absolutePath(from relative: String) -> String {
        return podTargetAbsoluteRoot.appendingPath(relative)
    }

    func relativePath(from absolute: String) -> String {
        return absolute
            .deletingSuffix("/")
            .deletingPrefix(podTargetAbsoluteRoot)
            .deletingPrefix("/")
    }
    func defaultVersion(for platform: Platform) -> String {
        switch platform {
        case .ios:
            return minIosPlatform
        case .osx:
            return Self.defaultVersion(for: platform)
        case .tvos:
            return Self.defaultVersion(for: platform)
        case .watchos:
            return Self.defaultVersion(for: platform)
        }
    }

    func resolvePlatforms(_ platforms: [String: String]) -> [String: String] {
        var platforms = platforms
        if let iosPlatform = platforms["ios"],
           iosPlatform.compareVersion(minIosPlatform) == .orderedAscending {
            platforms["ios"] = minIosPlatform
        } else if platforms.isEmpty {
            platforms["ios"] = minIosPlatform
        }
        return platforms
    }
}

public struct BasicBuildOptions: BuildOptions {
    public let podName: String
    public let subspecs: [String]
    public let sourcePath: String
    public let platforms: [Platform]

    public let userOptions: [UserOption]
    public let minIosPlatform: String
    public let depsPrefix: String
    public let podsRoot: String
    public let useFrameworks: Bool

    public init(podName: String,
                subspecs: [String],
                sourcePath: String,
                platforms: [Platform],
                userOptions: [UserOption],
                minIosPlatform: String,
                depsPrefix: String,
                podsRoot: String,
                dynamicFrameworks: Bool) {
        self.podName = podName
        self.subspecs = subspecs
        self.sourcePath = sourcePath
        self.platforms = platforms
        self.userOptions = userOptions
        self.minIosPlatform = minIosPlatform
        self.depsPrefix = depsPrefix
        self.podsRoot = podsRoot
        self.useFrameworks = dynamicFrameworks
    }

    public var podTargetSrcRoot: String {
        return podsRoot.appendingPath(podName)
    }

    public var podTargetAbsoluteRoot: String {
        var result = sourcePath
        if podsRoot.hasPrefix("/") {
            result = podsRoot
        } else {
            result = result.appendingPath(podsRoot.lastPath)
        }
        return result.appendingPath(podName)
    }
}

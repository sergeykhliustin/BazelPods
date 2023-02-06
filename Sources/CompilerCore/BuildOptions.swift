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
    var podspecPath: String { get }
    var sourcePath: String { get }

    var platforms: [Platform] { get }

    var minIosPlatform: String? { get }

    var depsPrefix: String { get }
    var podsRoot: String { get }

    var useFrameworks: Bool { get }

    var userOptions: [String] { get }
    var globalCopts: [String] { get }

    var podTargetSrcRoot: String { get }

    var podTargetAbsoluteRoot: String { get }

    func getRulePrefix(name: String) -> String
}

extension BuildOptions {
    func relativePath(from absolute: String) -> String {
        return absolute
            .deletingSuffix("/")
            .deletingPrefix(podTargetAbsoluteRoot)
            .deletingPrefix("/")
    }
    func defaultVersion(for platform: Platform) -> String {
        switch platform {
        case .ios:
            return minIosPlatform ?? "13.0"
        case .osx:
            return "10.13"
        case .tvos:
            return "13.0"
        case .watchos:
            return "8.0"
        }
    }

    func resolvePlatforms(_ platforms: [String: String]) -> [String: String] {
        var platforms = platforms
        if let iosPlatform = platforms["ios"],
            let minIosPlatform,
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
    public let podspecPath: String
    public let sourcePath: String
    public let platforms: [Platform]

    public let userOptions: [String]
    public let globalCopts: [String]
    public let minIosPlatform: String?
    public let depsPrefix: String
    public let podsRoot: String
    public let useFrameworks: Bool

    public init(podName: String = "",
                subspecs: [String] = [],
                podspecPath: String = "",
                sourcePath: String = "",
                platforms: [Platform] = [.ios],
                userOptions: [String] = [],
                globalCopts: [String] = [],
                minIosPlatform: String? = nil,
                depsPrefix: String = "//Pods",
                podsRoot: String = "Pods",
                dynamicFrameworks: Bool = false) {
        self.podName = podName
        self.subspecs = subspecs
        self.podspecPath = podspecPath
        self.sourcePath = sourcePath
        self.platforms = platforms
        self.userOptions = userOptions
        self.globalCopts = globalCopts
        self.minIosPlatform = minIosPlatform
        self.depsPrefix = depsPrefix
        self.podsRoot = podsRoot
        self.useFrameworks = dynamicFrameworks
    }

    public static let empty = BasicBuildOptions(podName: "")

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

    public func getRulePrefix(name: String) -> String {
        return "\(depsPrefix)/\(name)"
    }
}

//
//  BuildOptions.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 3/25/2020.
//  Copyright © 2020 Pinterest Inc. All rights reserved.

import Foundation

public protocol BuildOptions {
    var podName: String { get }
    var subspecs: [String] { get }
    var podspecPath: String { get }
    var sourcePath: String { get }

    var iosPlatform: String { get }

    var depsPrefix: String { get }
    var podsRoot: String { get }

    var dynamicFrameworks: Bool { get }

    var userOptions: [String] { get }
    var globalCopts: [String] { get }

    var podTargetSrcRoot: String { get }

    var podTargetAbsoluteRoot: String { get }

    func getRulePrefix(name: String) -> String
}

public struct BasicBuildOptions: BuildOptions {
    public let podName: String
    public let subspecs: [String]
    public let podspecPath: String
    public let sourcePath: String

    public let userOptions: [String]
    public let globalCopts: [String]
    public let iosPlatform: String
    public let depsPrefix: String
    public let podsRoot: String
    public let dynamicFrameworks: Bool

    public init(podName: String = "",
                subspecs: [String] = [],
                podspecPath: String = "",
                sourcePath: String = "",
                userOptions: [String] = [],
                globalCopts: [String] = [],
                iosPlatform: String = "13.0",
                depsPrefix: String = "//Pods",
                podsRoot: String = "Pods",
                dynamicFrameworks: Bool = false) {
        self.podName = podName
        self.subspecs = subspecs
        self.podspecPath = podspecPath
        self.sourcePath = sourcePath
        self.userOptions = userOptions
        self.globalCopts = globalCopts
        self.iosPlatform = iosPlatform
        self.depsPrefix = depsPrefix
        self.podsRoot = podsRoot
        self.dynamicFrameworks = dynamicFrameworks
    }

    public static let empty = BasicBuildOptions(podName: "")

    public var podTargetSrcRoot: String {
        return podsRoot.appendingPath(podName)
    }

    public var podTargetAbsoluteRoot: String {
        return sourcePath.appendingPath(podsRoot.lastPath).appendingPath(podName)
    }

    public func getRulePrefix(name: String) -> String {
        return "\(depsPrefix)/\(name)"
    }
}

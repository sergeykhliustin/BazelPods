//
//  BuildOptions.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 3/25/2020.
//  Copyright © 2020 Pinterest Inc. All rights reserved.

public protocol BuildOptions {
    var podName: String { get }
    var subspecs: [String] { get }
    var podspecPath: String { get }
    var sourcePath: String { get }

    var userOptions: [String] { get }
    var globalCopts: [String] { get }

    var path: String { get }
    var iosPlatform: String { get }

    var podBaseDir: String { get }
    var genfileOutputBaseDir: String { get }
}

public struct BasicBuildOptions: BuildOptions {
    public let podName: String
    public let subspecs: [String]
    public let podspecPath: String
    public let sourcePath: String

    public let userOptions: [String]
    public let globalCopts: [String]
    public let path: String
    public let iosPlatform: String

    public init(podName: String = "",
                subspecs: [String] = [],
                podspecPath: String = "",
                sourcePath: String = "",
                path: String = ".",
                userOptions: [String] = [],
                globalCopts: [String] = [],
                iosPlatform: String = "13.0"
    ) {
        self.podName = podName
        self.subspecs = subspecs
        self.path = path
        self.podspecPath = podspecPath
        self.sourcePath = sourcePath
        self.userOptions = userOptions
        self.globalCopts = globalCopts
        self.iosPlatform = iosPlatform
    }

    public static let empty = BasicBuildOptions(podName: "")

    public var podBaseDir: String {
        return "Pods"
    }

    public var genfileOutputBaseDir: String {
        let basePath = "Pods"
        let podName = podName
        let parts = path.split(separator: "/")
        if path ==  "." || parts.count < 2 {
            return "\(basePath)/\(podName)"
        }

        return String(parts[0..<2].joined(separator: "/"))
    }
}

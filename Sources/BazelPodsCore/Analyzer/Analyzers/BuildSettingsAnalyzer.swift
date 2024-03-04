//
//  BuildSettingsAnalyzer.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 08.02.2023.
//

import Foundation

struct BuildSettingsAnalyzer<S: XCConfigRepresentable> {
    struct Result {
        let swiftCopts: [String]
        let objcCopts: [String]
        let linkOpts: [String]
        let objcDefines: [String]
        let xcconfig: [String: StarlarkNode]
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

    var result: Result {
        return run()
    }

    private func run() -> Result {
        let xcconfig = spec.collectAttribute(with: subspecs, keyPath: \.xcconfig).platform(platform) ?? [:]
        let podTargetXcconfig = spec.collectAttribute(with: subspecs, keyPath: \.podTargetXcconfig).platform(platform) ?? [:]
        let userTargetXcconfig = spec.collectAttribute(with: subspecs, keyPath: \.userTargetXcconfig).platform(platform) ?? [:]
        let mergedConfig = xcconfig
            .merging(podTargetXcconfig, uniquingKeysWith: { $1 })
            .merging(userTargetXcconfig, uniquingKeysWith: { $1 })
        let parser = XCConfigParser(mergedConfig, options: options)

        return Result(
            swiftCopts: parser.swiftCopts,
            objcCopts: parser.objcCopts,
            linkOpts: parser.linkOpts,
            objcDefines: parser.objcDefines,
            xcconfig: parser.xcconfig
        )
    }
}

//
//  BuildSettingsAnalyzer.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 08.02.2023.
//

import Foundation

struct BuildSettingsAnalyzer<S: XCConfigRepresentable> {
    struct Result {
        var swiftCopts: [String]
        var objcCopts: [String]
        var ccCopts: [String]
        var linkOpts: [String]
        var objcDefines: [String]
        var xcconfig: [String: StarlarkNode]
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
        let parser = XCConfigParser(spec: spec, subspecs: subspecs, platform: platform, options: options)

        return Result(
            swiftCopts: parser.swiftCopts,
            objcCopts: parser.objcCopts,
            ccCopts: parser.ccCopts,
            linkOpts: parser.linkOpts,
            objcDefines: parser.objcDefines,
            xcconfig: parser.xcconfig
        )
    }
}

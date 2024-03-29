//
//  SdkDependenciesAnalyzer.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 06.02.2023.
//

import Foundation

struct SdkDependenciesAnalyzer<S: SdkDependenciesRepresentable> {
    struct Result {
        var sdkDylibs: [String]
        var sdkFrameworks: [String]
        var weakSdkFrameworks: [String]
        var testonly: Bool
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
        let sdkDylibs = spec.collectAttribute(with: subspecs, keyPath: \.libraries).platform(platform) ?? []
        let sdkFrameworks = spec.collectAttribute(with: subspecs, keyPath: \.frameworks).platform(platform) ?? []
        let weakSdkFrameworks = spec.collectAttribute(with: subspecs, keyPath: \.weakFrameworks).platform(platform) ?? []
        let testonly = (sdkFrameworks + weakSdkFrameworks).contains("XCTest")
        return Result(
            sdkDylibs: sdkDylibs,
            sdkFrameworks: sdkFrameworks,
            weakSdkFrameworks: weakSdkFrameworks,
            testonly: testonly
        )
    }
}

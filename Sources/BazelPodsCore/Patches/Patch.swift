//
//  Patch.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 15.02.2023.
//

import Foundation

public enum PatchType: String, CaseIterable {
    case bundle_deduplicate
    case arm64_to_sim
    case arm64_to_sim_forced
    case missing_sdks
    case user_options
}

public protocol Patch {
    func run(
        base: inout BaseAnalyzer.Result,
        sources: inout SourcesAnalyzer.Result,
        resources: inout ResourcesAnalyzer.Result,
        sdkDeps: inout SdkDependenciesAnalyzer.Result,
        vendoredDeps: inout VendoredDependenciesAnalyzer.Result,
        podDeps: inout PodDependenciesAnalyzer.Result,
        buildSettings: inout BuildSettingsAnalyzer.Result
    )
}

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
    case user_options
}

protocol Patch {
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

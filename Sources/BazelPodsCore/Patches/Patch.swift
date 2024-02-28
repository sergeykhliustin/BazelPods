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

protocol Patch {
    func run<S>(
        base: inout BaseAnalyzer<S>.Result,
        sources: inout SourcesAnalyzer<S>.Result,
        resources: inout ResourcesAnalyzer<S>.Result,
        sdkDeps: inout SdkDependenciesAnalyzer<S>.Result,
        vendoredDeps: inout VendoredDependenciesAnalyzer<S>.Result,
        podDeps: inout PodDependenciesAnalyzer<S>.Result,
        buildSettings: inout BuildSettingsAnalyzer<S>.Result
    )
}

protocol TestSpecSpecificPatch {
    func run<S>(
        base: inout BaseAnalyzer<S>.Result,
        sources: inout SourcesAnalyzer<S>.Result,
        resources: inout ResourcesAnalyzer<S>.Result,
        sdkDeps: inout SdkDependenciesAnalyzer<S>.Result,
        vendoredDeps: inout VendoredDependenciesAnalyzer<S>.Result,
        podDeps: inout PodDependenciesAnalyzer<S>.Result,
        buildSettings: inout BuildSettingsAnalyzer<S>.Result,
        environment: inout EnvironmentAnalyzer<S>.Result,
        runnerInfo: inout RunnerAnalyzer<S>.Result
    )
}

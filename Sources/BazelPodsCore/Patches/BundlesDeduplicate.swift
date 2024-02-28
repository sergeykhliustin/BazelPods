//
//  FrameworkBundlesDeduplicatePatch.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 15.02.2023.
//

import Foundation

/// Fixes issue when podspec includes bundle and static vendored framework where framework contains bundle with same name
/// See `GoogleMaps` `~ 7.3.0` as example
struct BundlesDeduplicate: Patch {
    func run<S>(
        base: inout BaseAnalyzer<S>.Result,
        sources: inout SourcesAnalyzer<S>.Result,
        resources: inout ResourcesAnalyzer<S>.Result,
        sdkDeps: inout SdkDependenciesAnalyzer<S>.Result,
        vendoredDeps: inout VendoredDependenciesAnalyzer<S>.Result,
        podDeps: inout PodDependenciesAnalyzer<S>.Result,
        buildSettings: inout BuildSettingsAnalyzer<S>.Result
    ) {

        var frameworksPaths = [String]()
        frameworksPaths = (vendoredDeps.frameworks + vendoredDeps.xcFrameworks)
            .reduce(into: frameworksPaths) { result, framework in
            if !framework.dynamic {
                result.append(framework.path)
            }
        }

        resources.precompiledBundles = resources.precompiledBundles
            .reduce(into: [String](), { result, bundle in
                if let path = frameworksPaths.first(where: { bundle.contains($0) }) {
                    log_info("Removing bundle \(bundle.lastPath) since \(path.lastPath) alredy includes it")
                } else {
                    result.append(bundle)
                }
            })
    }
}

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
    func run(base: inout BaseAnalyzer.Result,
             sources: inout SourcesAnalyzer.Result,
             resources: inout ResourcesAnalyzer.Result,
             sdkDeps: inout SdkDependenciesAnalyzer.Result,
             vendoredDeps: inout VendoredDependenciesAnalyzer.Result,
             podDeps: inout PodDependenciesAnalyzer.Result,
             buildSettings: inout BuildSettingsAnalyzer.Result) {

        var frameworksPaths = [String]()
        frameworksPaths = vendoredDeps.frameworks.reduce(into: frameworksPaths) { result, framework in
            if !framework.dynamic {
                result.append(framework.path)
            }
        }
        frameworksPaths = vendoredDeps.xcFrameworks.reduce(into: frameworksPaths) { result, framework in
            if !framework.dynamic {
                result.append(framework.path)
            }
        }

        resources.precompiledBundles = resources.precompiledBundles
            .reduce(into: [String](), { result, bundle in
                if let path = frameworksPaths.first(where: { bundle.contains($0) }) {
                    log_debug("Removed bundle \"\(bundle.lastPath)\" since conflicts with \"\(path.lastPath)\"")
                } else {
                    result.append(bundle)
                }
            })
    }
}

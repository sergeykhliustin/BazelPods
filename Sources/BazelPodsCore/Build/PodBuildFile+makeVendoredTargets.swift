//
//  PodBuildFile+makeVendoredTargets.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 08.02.2024.
//

import Foundation

extension PodBuildFile {
    static func makeVendoredTargets<S>(
        targetName: TargetName,
        baseInfo: BaseAnalyzer<S>.Result,
        vendored: VendoredDependenciesAnalyzer<S>.Result
    ) -> (targets: [BazelTarget], conditions: [String: [Arch]]) {
        var result = vendored.libraries.reduce(([BazelTarget](), [String: [Arch]]())) { partialResult, library in
            var targets = partialResult.0
            var conditions = partialResult.1
            let name = targetName.library(baseInfo.moduleName, library: library.name)
            conditions[name] = library.archs
            targets.append(ObjcImport(name: name, library: library.path))
            return (targets, conditions)
        }
        result = vendored.frameworks.reduce(result, { partialResult, framework in
            var targets = partialResult.0
            var conditions = partialResult.1
            let name = targetName.framework(baseInfo.moduleName, framework: framework.name)
            conditions[name] = framework.archs
            targets.append(AppleFrameworkImport(name: name, isDynamic: framework.dynamic, isXCFramework: false, frameworkImport: framework.path))
            return (targets, conditions)
        })
        result = vendored.xcFrameworks.reduce(result, { partialResult, xcFramework in
            var targets = partialResult.0
            var conditions = partialResult.1
            let name = targetName.xcframework(baseInfo.moduleName, xcframework: xcFramework.name)
            conditions[name] = xcFramework.archs
            targets.append(AppleFrameworkImport(name: name, isDynamic: xcFramework.dynamic, isXCFramework: true, frameworkImport: xcFramework.path))
            return (targets, conditions)
        })
        return result
    }
}

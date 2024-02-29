//
//  PodBuildFile+makeResourceBundles.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 08.02.2024.
//

import Foundation

extension PodBuildFile {
    static func makeResourceBundles<S>(
        targetName: TargetName,
        baseInfo: BaseAnalyzer<S>.Result,
        resources: ResourcesAnalyzer<S>.Result)
    -> (targets: [BazelTarget], infoplists: [InfoPlist<S>]) {
        var targets: [BazelTarget] = []
        var infoplists: [InfoPlist<S>] = []
        for bundle in resources.resourceBundles {
            let bundleRuleName = targetName.bundle(baseInfo.moduleName, bundle: bundle.name)
            let infoPlistRuleName = targetName.bundleInfoplist(baseInfo.moduleName, bundle: bundle.name)
            targets.append(AppleResourceBundle(name: bundleRuleName, bundle: bundle, infoplists: [infoPlistRuleName]))
            infoplists.append(InfoPlist(name: infoPlistRuleName, resourceBundle: bundle.name, info: baseInfo))
        }
        return (targets, infoplists)
    }
}

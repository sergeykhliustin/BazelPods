//
//  PodBuildFile+makeSourceLibs.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 08.02.2024.
//

import Foundation

extension PodBuildFile {
    static func makeSourceLibs(analyzer: BaseSpecAnalyzer<PodSpec>,
                               deps: [String],
                               conditionalDeps: [String: [Arch]])
    -> ([BazelTarget], [InfoPlist<PodSpec>]) {
        let info = analyzer.baseInfo
        var targets: [BazelTarget] = []
        var infoplists: [InfoPlist<PodSpec>] = []

        var infoplistRuleName: String?
        if analyzer.sourcesInfo.linkDynamic {
            let ruleName = analyzer.targetName.baseInfoplist(info.name)
            infoplists.append(InfoPlist(name: ruleName, framework: info))
            infoplistRuleName = ruleName
        }

        let framework = AppleFramework(name: analyzer.targetName.base(info.name),
                                       info: info,
                                       sources: analyzer.sourcesInfo,
                                       resources: analyzer.resourcesInfo,
                                       sdkDeps: analyzer.sdkDepsInfo,
                                       vendoredDeps: analyzer.vendoredDepsInfo,
                                       buildSettings: analyzer.buildSettingsInfo,
                                       infoplists: [infoplistRuleName].compactMap({ $0 }),
                                       deps: deps,
                                       conditionalDeps: conditionalDeps)
        targets.append(framework)

        return (targets, infoplists)
    }
}

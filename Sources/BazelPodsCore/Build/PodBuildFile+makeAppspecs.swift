//
//  PodBuildFile+makeAppspecs.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 08.02.2024.
//

import Foundation

extension PodBuildFile {
    static func makeAppspecs(spec: PodSpec, options: BuildOptions) -> [BazelTarget] {
        let appspecs = spec.selectedAppspecs(subspecs: options.subspecs)
        var output: [BazelTarget] = []
        for platform in options.platforms {
            let targetName = TargetName(platform: platform, platformSuffix: options.platforms.count > 1)
            for appspec in appspecs {
                let analyzer: BaseSpecAnalyzer<AppSpec>
                do {
                    analyzer = try BaseSpecAnalyzer(targetName: targetName,
                                                    platform: platform,
                                                    spec: appspec,
                                                    subspecs: [],
                                                    options: options)
                } catch {
                    log_debug(error)
                    continue
                }

                for patch in options.patches {

                }

                let (resourceTargets, resourceInfoplists) = makeResourceBundles(
                    targetName: targetName,
                    baseInfo: analyzer.baseInfo,
                    resources: analyzer.resourcesInfo)

                let (vendoredTargets, conditions) = makeVendoredTargets(
                    targetName: targetName,
                    baseInfo: analyzer.baseInfo,
                    vendored: analyzer.vendoredDepsInfo)

                let deps = (
                    (resourceTargets.map({ $0.name })) +
                    analyzer.podDepsInfo.dependencies +
                    [targetName.base(spec.name)]
                ).sorted()

                let infoPlist = InfoPlist(
                    name: targetName.appInfoplist(spec.name, appName: appspec.name),
                    application: analyzer.baseInfo,
                    spec: appspec
                )
                let bundleId: String
                if let value = appspec.infoPlist?[InfoPlist<AppSpec>.Keys.CFBundleIdentifier.rawValue] as? String {
                    bundleId = value
                } else {
                    bundleId = "org.cocoapods.\(spec.name)-\(appspec.name)"
                }
                let source = iOSApplication(
                    name: targetName.app(spec.name, appName: appspec.name),
                    info: analyzer.baseInfo,
                    sources: analyzer.sourcesInfo,
                    resources: analyzer.resourcesInfo,
                    deps: deps,
                    infoPlist: infoPlist.name,
                    bundleId: bundleId,
                    conditionalDeps: conditions)

                output += [source]
                output += resourceTargets
                output += resourceInfoplists
                output += [infoPlist]
                output += vendoredTargets
            }
        }
        return output
    }
}

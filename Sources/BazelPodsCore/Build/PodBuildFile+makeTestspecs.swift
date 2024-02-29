//
//  PodBuildFile+makeTestspecs.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 08.02.2024.
//

import Foundation

extension PodBuildFile {
    static func makeTestspecs(spec: PodSpec, options: BuildOptions) -> [BazelTarget] {
        let testspecs = spec.selectedTestspecs(subspecs: options.subspecs)
        var output: [BazelTarget] = []
        for platform in options.platforms {
            let targetName = TargetName(platform: platform, platformSuffix: options.platforms.count > 1)
            for testspec in testspecs {
                let analyzer: TestSpecAnalyzer<TestSpec>
                do {
                    analyzer = try TestSpecAnalyzer(targetName: targetName,
                                                    platform: platform,
                                                    spec: testspec,
                                                    subspecs: [],
                                                    options: options)
                } catch {
                    log_debug(error)
                    continue
                }
                let (resourceTargets, resourceInfoplists) = makeResourceBundles(
                    targetName: targetName,
                    baseInfo: analyzer.baseInfo,
                    resources: analyzer.resourcesInfo)
                let deps = (
                    (resourceTargets.map({ $0.name })) +
                    analyzer.podDepsInfo.dependencies +
                    [targetName.base(spec.name)]
                ).sorted()

                let (vendoredTargets, conditions) = makeVendoredTargets(
                    targetName: targetName,
                    baseInfo: analyzer.baseInfo,
                    vendored: analyzer.vendoredDepsInfo)

                var testHost: String?
                var appHostTargets: [BazelTarget] = []

                if testspec.requiresAppHost {
                    if let appHostName = testspec.appHostName {
                        testHost = targetName.app(spec.name, appName: appHostName)
                    } else {
                        testHost = targetName.appHostName(spec.name, testspec: testspec.name)
                        appHostTargets = makeAppHost(spec: spec,
                                                     testspec: testspec,
                                                     targetName: targetName,
                                                     info: analyzer.baseInfo,
                                                     options: options)
                    }
                }

                let infoPlist = InfoPlist(
                    name: targetName.testsInfoplist(spec.name, testspec: testspec.name),
                    test: analyzer.baseInfo,
                    spec: testspec
                )

                let source: BazelTarget

                switch testspec.testType {
                case .unit:
                    source = iOSUnitTest(
                        name: targetName.tests(spec.name, testspec: testspec.name),
                        info: analyzer.baseInfo,
                        sources: analyzer.sourcesInfo,
                        resources: analyzer.resourcesInfo,
                        deps: deps,
                        timeout: options.testsTimeout?.rawValue ?? "",
                        testHost: testHost,
                        infoPlist: infoPlist.name,
                        environment: analyzer.environmentInfo.environmentVariables,
                        launchArguments: analyzer.environmentInfo.launchArguments,
                        conditionalDeps: conditions,
                        runner: analyzer.runnerInfo.runnerName)
                case .ui:
                    source = iOSUITest(
                        name: targetName.tests(spec.name, testspec: testspec.name),
                        info: analyzer.baseInfo,
                        sources: analyzer.sourcesInfo,
                        resources: analyzer.resourcesInfo,
                        deps: deps,
                        timeout: options.testsTimeout?.rawValue ?? "",
                        testHost: testHost,
                        infoPlist: infoPlist.name,
                        environment: analyzer.environmentInfo.environmentVariables,
                        launchArguments: analyzer.environmentInfo.launchArguments,
                        conditionalDeps: conditions,
                        runner: analyzer.runnerInfo.runnerName)
                }

                output += [source]
                output += resourceTargets
                output += resourceInfoplists
                output += [infoPlist]
                output += appHostTargets
                output += vendoredTargets
            }
        }
        return output
    }
}

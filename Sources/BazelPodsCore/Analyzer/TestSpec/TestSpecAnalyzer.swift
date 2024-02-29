//
//  TestSpecAnalyzer.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 27.02.2024.
//

import Foundation

final class TestSpecAnalyzer<S: TestSpecRepresentable>: BaseSpecAnalyzer<S> {
    var environmentInfo: EnvironmentAnalyzer<S>.Result
    var runnerInfo: RunnerAnalyzer<S>.Result

    override init(targetName: TargetName,
                  platform: Platform,
                  spec: S,
                  subspecs: [S],
                  options: BuildOptions) throws {
        environmentInfo = EnvironmentAnalyzer(spec: spec, options: options).result
        runnerInfo = RunnerAnalyzer(spec: spec, options: options).result
        try super.init(
            targetName: targetName,
            platform: platform,
            spec: spec,
            subspecs: subspecs,
            options: options
        )
    }

    override func patch(_ patch: Patch) {
        super.patch(patch)
        guard let patch = patch as? TestSpecSpecificPatch else { return }
        patch.run(base: &baseInfo,
                  sources: &sourcesInfo,
                  resources: &resourcesInfo,
                  sdkDeps: &sdkDepsInfo,
                  vendoredDeps: &vendoredDepsInfo,
                  podDeps: &podDepsInfo,
                  buildSettings: &buildSettingsInfo,
                  environment: &environmentInfo,
                  runnerInfo: &runnerInfo)
    }
}

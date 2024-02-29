//
//  BaseSpecAnalyzer.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 01.02.2024.
//

import Foundation

typealias SpecRepresentable = BaseRepresentable &
BaseInfoRepresentable &
SourceFilesRepresentable &
SdkDependenciesRepresentable &
ResourcesRepresentable &
PodDependenciesRepresentable &
XCConfigRepresentable &
InfoPlistRepresentable &
VendoredDependenciesRepresentable

class BaseSpecAnalyzer<S: SpecRepresentable> {
    let targetName: TargetName

    private let platform: Platform
    private let spec: S
    private let options: BuildOptions

    var baseInfo: BaseAnalyzer<S>.Result
    var sourcesInfo: SourcesAnalyzer<S>.Result
    var sdkDepsInfo: SdkDependenciesAnalyzer<S>.Result
    var resourcesInfo: ResourcesAnalyzer<S>.Result
    var podDepsInfo: PodDependenciesAnalyzer<S>.Result
    var buildSettingsInfo: BuildSettingsAnalyzer<S>.Result
    var vendoredDepsInfo: VendoredDependenciesAnalyzer<S>.Result

    init(targetName: TargetName,
         platform: Platform,
         spec: S,
         subspecs: [S],
         options: BuildOptions) throws {
        self.platform = platform
        self.spec = spec
        self.options = options
        self.targetName = targetName

        baseInfo = try BaseAnalyzer(platform: platform,
                                    spec: spec,
                                    subspecs: subspecs,
                                    options: options).run()
        sourcesInfo = SourcesAnalyzer(platform: platform,
                                      spec: spec,
                                      subspecs: subspecs,
                                      options: options).result
        sdkDepsInfo = SdkDependenciesAnalyzer(platform: platform,
                                              spec: spec,
                                              subspecs: subspecs,
                                              options: options).result
        resourcesInfo = ResourcesAnalyzer(platform: platform,
                                          spec: spec,
                                          subspecs: subspecs,
                                          options: options).result
        podDepsInfo = PodDependenciesAnalyzer(platform: platform,
                                                   spec: spec,
                                                   subspecs: subspecs,
                                                   options: options,
                                                   targetName: targetName).result
        buildSettingsInfo = BuildSettingsAnalyzer(platform: platform,
                                                  spec: spec,
                                                  subspecs: subspecs,
                                                  options: options).result

        vendoredDepsInfo = VendoredDependenciesAnalyzer(platform: platform,
                                                        spec: spec,
                                                        subspecs: subspecs,
                                                        options: options).result
        applyPatches()
    }

    private func applyPatches() {
        for patch in options.patches {
            switch patch {
            case .bundle_deduplicate:
                self.patch(BundlesDeduplicate())
            case .arm64_to_sim:
                if options.hostArm64 {
                    self.patch(Arm64ToSimPatch(options: options, platform: platform))
                }
            case .arm64_to_sim_forced:
                self.patch(Arm64ToSimPatch(options: options, platform: platform))
            case .missing_sdks:
                self.patch(MissingSdksPatch(options, platform: platform))
            case .user_options:
                self.patch(UserOptionsPatch(options, platform: platform))
            }
        }

        if !options.patches.contains(.user_options) && !options.userOptions.isEmpty {
            self.patch(UserOptionsPatch(options, platform: platform))
        }
    }

    func patch(_ patch: Patch) {
        patch.run(base: &baseInfo,
                  sources: &sourcesInfo,
                  resources: &resourcesInfo,
                  sdkDeps: &sdkDepsInfo,
                  vendoredDeps: &vendoredDepsInfo,
                  podDeps: &podDepsInfo,
                  buildSettings: &buildSettingsInfo)
    }
}

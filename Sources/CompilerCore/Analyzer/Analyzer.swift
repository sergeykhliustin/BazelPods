//
//  Analyzer.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 08.02.2023.
//

import Foundation

public struct Analyzer {
    private let platform: Platform
    private let spec: PodSpec
    private let subspecs: [PodSpec]
    private let options: BuildOptions

    var baseInfo: BaseAnalyzer.Result
    var sourcesInfo: SourcesAnalyzer.Result
    var resourcesInfo: ResourcesAnalyzer.Result
    var sdkDepsInfo: SdkDependenciesAnalyzer.Result
    var vendoredDepsInfo: VendoredDependenciesAnalyzer.Result
    var podDepsInfo: PodDependenciesAnalyzer.Result
    var buildSettingsInfo: BuildSettingsAnalyzer.Result

    init(platform: Platform,
         spec: PodSpec,
         subspecs: [PodSpec],
         options: BuildOptions) {
        self.platform = platform
        self.spec = spec
        self.subspecs = subspecs
        self.options = options

        baseInfo = BaseAnalyzer(platform: platform,
                                spec: spec,
                                subspecs: subspecs,
                                options: options).result
        sourcesInfo = SourcesAnalyzer(platform: platform,
                                      spec: spec,
                                      subspecs: subspecs,
                                      options: options).result
        resourcesInfo = ResourcesAnalyzer(platform: platform,
                                          spec: spec,
                                          subspecs: subspecs,
                                          options: options).result
        sdkDepsInfo = SdkDependenciesAnalyzer(platform: platform,
                                              spec: spec,
                                              subspecs: subspecs,
                                              options: options).result
        vendoredDepsInfo = VendoredDependenciesAnalyzer(platform: platform,
                                                        spec: spec,
                                                        subspecs: subspecs,
                                                        options: options).result
        podDepsInfo = PodDependenciesAnalyzer(platform: platform,
                                              spec: spec,
                                              subspecs: subspecs,
                                              options: options).result
        buildSettingsInfo = BuildSettingsAnalyzer(platform: platform,
                                                  spec: spec,
                                                  subspecs: subspecs,
                                                  options: options).result
    }
}

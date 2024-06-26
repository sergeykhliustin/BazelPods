//
//  UserOptionsPatch.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 15.02.2023.
//

import Foundation

struct UserOptionsPatch: Patch, TestSpecSpecificPatch {
    private let options: BuildOptions
    private let platform: Platform

    init(_ options: BuildOptions, platform: Platform) {
        self.options = options
        self.platform = platform
    }

    func run<S>(
        base: inout BaseAnalyzer<S>.Result,
        sources: inout SourcesAnalyzer<S>.Result,
        resources: inout ResourcesAnalyzer<S>.Result,
        sdkDeps: inout SdkDependenciesAnalyzer<S>.Result,
        vendoredDeps: inout VendoredDependenciesAnalyzer<S>.Result,
        podDeps: inout PodDependenciesAnalyzer<S>.Result,
        buildSettings: inout BuildSettingsAnalyzer<S>.Result
    ) {
        let userOptions = options.userOptions
            .filter({
                $0.name == base.name || $0.name == options.podName.appendingPath(base.name)
            })
            .filter({
                guard let platform = $0.platform else { return true }
                return platform == self.platform
            })
        for option in userOptions {
            switch option.attribute {
            case .sdk_frameworks(let value):
                switch option.opt {
                case .append:
                    sdkDeps.sdkFrameworks += value.filter({ !sdkDeps.sdkFrameworks.contains($0) })
                case .delete:
                    sdkDeps.sdkFrameworks.removeAll(where: { value.contains($0) })
                case .replace:
                    sdkDeps.sdkFrameworks = value
                }
            case .sdk_dylibs(let value):
                switch option.opt {
                case .append:
                    sdkDeps.sdkDylibs += value.filter({ !sdkDeps.sdkDylibs.contains($0) })
                case .delete:
                    sdkDeps.sdkDylibs.removeAll(where: { value.contains($0) })
                case .replace:
                    sdkDeps.sdkDylibs = value
                }
            case .weak_sdk_frameworks(let value):
                switch option.opt {
                case .append:
                    sdkDeps.weakSdkFrameworks += value.filter({ !sdkDeps.weakSdkFrameworks.contains($0) })
                case .delete:
                    sdkDeps.weakSdkFrameworks.removeAll(where: { value.contains($0) })
                case .replace:
                    sdkDeps.weakSdkFrameworks = value
                }
            case .vendored_libraries(let value):
                if option.opt == .delete {
                    vendoredDeps.libraries.removeAll(where: { value.contains($0.name) })
                }
            case .vendored_frameworks(let value):
                if option.opt == .delete {
                    vendoredDeps.frameworks.removeAll(where: { value.contains($0.name) })
                }
            case .vendored_xcframeworks(let value):
                if option.opt == .delete {
                    vendoredDeps.xcFrameworks.removeAll(where: { value.contains($0.name) })
                }
            case .testonly(let value):
                if option.opt == .replace {
                    sdkDeps.testonly = value
                }
            case .link_dynamic(let value):
                if option.opt == .replace {
                    sources.linkDynamic = value
                }
            case .data(let value):
                switch option.opt {
                case .append:
                    resources.resources += value.filter({ !resources.resources.contains($0) })
                case .delete:
                    resources.resources.removeAll(where: { value.contains($0) })
                case .replace:
                    resources.resources = value
                }
            case .objc_defines(let value):
                switch option.opt {
                case .append:
                    buildSettings.objcDefines += value.filter({ !buildSettings.objcDefines.contains($0) })
                case .delete:
                    buildSettings.objcDefines.removeAll(where: { value.contains($0) })
                case .replace:
                    buildSettings.objcDefines = value
                }
            case .runner:
                // test spec specific option
                break
            case .test_host:
                // test spec specific option
                break
            case .timeout:
                // test spec specific option
                break
            case .objc_copts(let value):
                switch option.opt {
                case .append:
                    buildSettings.objcCopts += value
                case .delete:
                    buildSettings.objcCopts.removeAll(where: { value.contains($0) })
                case .replace:
                    buildSettings.objcCopts = value
                }
            case .swift_copts(let value):
                switch option.opt {
                case .append:
                    buildSettings.swiftCopts += value
                case .delete:
                    buildSettings.swiftCopts.removeAll(where: { value.contains($0) })
                case .replace:
                    buildSettings.swiftCopts = value
                }
            case .cc_copts(let value):
                switch option.opt {
                case .append:
                    buildSettings.ccCopts += value
                case .delete:
                    buildSettings.ccCopts.removeAll(where: { value.contains($0) })
                case .replace:
                    buildSettings.ccCopts = value
                }
            case .linkopts(let value):
                switch option.opt {
                case .append:
                    buildSettings.linkOpts += value
                case .delete:
                    buildSettings.linkOpts.removeAll(where: { value.contains($0) })
                case .replace:
                    buildSettings.linkOpts = value
                }
            }
        }
    }

    func run<S>(
        base: inout BaseAnalyzer<S>.Result,
        sources: inout SourcesAnalyzer<S>.Result,
        resources: inout ResourcesAnalyzer<S>.Result,
        sdkDeps: inout SdkDependenciesAnalyzer<S>.Result,
        vendoredDeps: inout VendoredDependenciesAnalyzer<S>.Result,
        podDeps: inout PodDependenciesAnalyzer<S>.Result,
        buildSettings: inout BuildSettingsAnalyzer<S>.Result,
        environment: inout EnvironmentAnalyzer<S>.Result,
        runnerInfo: inout RunnerAnalyzer<S>.Result
    ) {
        let userOptions = options.userOptions
            .filter({
                $0.name == base.name || $0.name == options.podName.appendingPath(base.name)
            })
            .filter({
                guard let platform = $0.platform else { return true }
                return platform == self.platform
            })
        for option in userOptions {
            switch option.attribute {
            case .runner(let string):
                runnerInfo.runnerName = string
            case .test_host(let string):
                runnerInfo.testHost = string
            case .timeout(let timeout):
                runnerInfo.timeout = timeout
            default:
                break
            }
        }
    }
}

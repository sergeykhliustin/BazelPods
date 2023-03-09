//
//  UserOptionsPatch.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 15.02.2023.
//

import Foundation

struct UserOptionsPatch: Patch {
    private let options: [UserOption]
    private let platform: Platform

    init(_ options: [UserOption], platform: Platform) {
        self.options = options
        self.platform = platform
    }

    func run(base: inout BaseAnalyzer.Result,
             sources: inout SourcesAnalyzer.Result,
             resources: inout ResourcesAnalyzer.Result,
             sdkDeps: inout SdkDependenciesAnalyzer.Result,
             vendoredDeps: inout VendoredDependenciesAnalyzer.Result,
             podDeps: inout PodDependenciesAnalyzer.Result,
             buildSettings: inout BuildSettingsAnalyzer.Result) {
        let options = options
            .filter({ $0.name == base.name })
            .filter({
                guard let platform = $0.platform else { return true }
                return platform == self.platform
            })
        for option in options {
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
            }
        }
    }
}

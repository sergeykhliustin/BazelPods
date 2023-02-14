//
//  ObjcLibrary.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 08.02.2023.
//

import Foundation

struct AppleLibrary: BazelTarget {
    let loadNode = "load('@build_bazel_rules_ios//rules:library.bzl', 'apple_library')"
    let name: String

    let info: BaseAnalyzer.Result
    let sources: SourcesAnalyzer.Result
    let resources: ResourcesAnalyzer.Result

    var deps: [String]
    var conditionalDeps: [String: [Arch]]

    var sdkDylibs: [String]
    var sdkFrameworks: [String]
    var weakSdkFrameworks: [String]

    let objcCopts: [String]
    let linkOpts: [String]
    var testonly: Bool

    init(name: String,
         info: BaseAnalyzer.Result,
         sources: SourcesAnalyzer.Result,
         resources: ResourcesAnalyzer.Result,
         sdkDeps: SdkDependenciesAnalyzer.Result,
         vendoredDeps: VendoredDependenciesAnalyzer.Result,
         buildSettings: BuildSettingsAnalyzer.Result,
         infoplists: [String],
         deps: [String],
         conditionalDeps: [String: [Arch]]) {

        self.name = name
        self.info = info
        self.sources = sources
        self.resources = resources

        self.deps = deps
        self.conditionalDeps = conditionalDeps
        self.sdkDylibs = sdkDeps.sdkDylibs
        self.sdkFrameworks = sdkDeps.sdkFrameworks
        self.weakSdkFrameworks = sdkDeps.weakSdkFrameworks

        self.objcCopts = buildSettings.objcCopts
        self.linkOpts = buildSettings.linkOpts
        self.testonly = sdkDeps.testonly
    }

    func toStarlark() -> StarlarkNode {
        let hdrs = sources.publicHeaders

        let baseDeps = deps.map({ !$0.hasPrefix("/") ? ":" + $0 : $0 })
        var conditionalDepsMap = self.conditionalDeps.reduce([String: [String]]()) { partialResult, element in
            var result = partialResult
            element.value.forEach({
                let conditon = ":" + $0.rawValue
                let name = ":" + element.key
                var arr = result[conditon] ?? []
                arr.append(name)
                result[conditon] = arr
            })
            return result
        }.mapValues({ $0.sorted(by: <) })

        let deps: StarlarkNode
        if conditionalDepsMap.isEmpty {
            deps = baseDeps.toStarlark()
        } else {
            conditionalDepsMap["//conditions:default"] = []
            let conditionalDeps: StarlarkNode =
                .functionCall(name: "select",
                              arguments: [
                                .basic(conditionalDepsMap.toStarlark())
                              ])
            if baseDeps.isEmpty {
                deps = conditionalDeps
            } else {
                deps = .expr(lhs: baseDeps.toStarlark(), op: "+", rhs: conditionalDeps)
            }
        }

        let lines: [StarlarkFunctionArgument] = [
            .named(name: "name", value: name.toStarlark()),
            .named(name: "module_name", value: info.moduleName.toStarlark()),
            .named(name: "testonly", value: testonly.toStarlark()),
            .named(name: "srcs", value: sources.sourceFiles.toStarlark()),
            .named(name: "hdrs", value: hdrs.toStarlark()),
            .named(name: "deps", value: deps.toStarlark()),
            .named(name: "sdk_dylibs", value: sdkDylibs.toStarlark()),
            .named(name: "sdk_frameworks", value: sdkFrameworks.toStarlark()),
            .named(name: "weak_sdk_frameworks", value: weakSdkFrameworks.toStarlark()),
            .named(name: "copts", value: objcCopts.toStarlark()),
            .named(name: "linkopts", value: linkOpts.toStarlark()),
            .named(name: "visibility", value: ["//visibility:public"].toStarlark())
        ]
            .filter({
                switch $0 {
                case .basic:
                    return true
                case .named(_, let value):
                    return !value.isEmpty
                }
            })
        return .functionCall(
            name: "apple_library",
            arguments: lines
        )
    }
}

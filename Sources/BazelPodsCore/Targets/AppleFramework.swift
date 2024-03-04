//
//  AppleFramework.swift
//  PodToBUILD
//
//  Created by Sergey Khliustin on 04.08.2022.
//

struct AppleFramework: BazelTarget {
    let loadNode = "load('@build_bazel_rules_ios//rules:framework.bzl', 'apple_framework')"

    let name: String

    let info: BaseAnalyzer<PodSpec>.Result
    let sources: SourcesAnalyzer<PodSpec>.Result
    let resources: ResourcesAnalyzer<PodSpec>.Result
    let infoplists: [String]

    let deps: [String]
    let conditionalDeps: [String: [Arch]]

    let objcDefines: AttrSet<[String]>
    let swiftDefines: AttrSet<[String]>

    let sdkDylibs: [String]
    let sdkFrameworks: [String]
    let weakSdkFrameworks: [String]

    let objcCopts: [String]
    let swiftCopts: [String]
    let linkOpts: [String]

    var linkDynamic: Bool
    var testonly: Bool

    let xcconfig: [String: StarlarkNode]

    init(name: String,
         info: BaseAnalyzer<PodSpec>.Result,
         sources: SourcesAnalyzer<PodSpec>.Result,
         resources: ResourcesAnalyzer<PodSpec>.Result,
         sdkDeps: SdkDependenciesAnalyzer<PodSpec>.Result,
         vendoredDeps: VendoredDependenciesAnalyzer<PodSpec>.Result,
         buildSettings: BuildSettingsAnalyzer<PodSpec>.Result,
         infoplists: [String],
         deps: [String],
         conditionalDeps: [String: [Arch]] = [:]) {

        self.name = name

        self.info = info
        self.sources = sources
        self.resources = resources
        self.infoplists = infoplists

        self.deps = deps
        self.conditionalDeps = conditionalDeps

        self.swiftDefines = AttrSet(basic: ["COCOAPODS"])
        self.objcDefines = AttrSet(basic: ["COCOAPODS=1"] + buildSettings.objcDefines)

        sdkDylibs = sdkDeps.sdkDylibs
        sdkFrameworks = sdkDeps.sdkFrameworks
        weakSdkFrameworks = sdkDeps.weakSdkFrameworks

        self.xcconfig = buildSettings.xcconfig
        self.objcCopts = buildSettings.objcCopts
        self.swiftCopts = buildSettings.swiftCopts
        self.linkOpts = buildSettings.linkOpts

        self.testonly = sdkDeps.testonly
        self.linkDynamic = sources.linkDynamic
    }

    func toStarlark() -> StarlarkNode {
        let basicSwiftDefines: StarlarkNode =
            .functionCall(name: "select",
                          arguments: [
                            .basic([
                                "//conditions:default": [
                                    "DEBUG"
                                ]
                            ].toStarlark())
                          ]
            )
        let basicObjcDefines: StarlarkNode =
            .functionCall(name: "select",
                          arguments: [
                            .basic([
                                ":release": [
                                    "POD_CONFIGURATION_RELEASE=1"
                                 ],
                                "//conditions:default": [
                                    "POD_CONFIGURATION_DEBUG=1",
                                    "DEBUG=1"
                                ]
                            ].toStarlark())
                          ])

        let swiftDefines = self.swiftDefines.toStarlark() .+. basicSwiftDefines
        let objcDefines = self.objcDefines.toStarlark() .+. basicObjcDefines

        let deps = makeDeps(deps: deps, conditionalDeps: conditionalDeps)

        let bundleId = "org.cocoapods.\(info.name)"

        let lines: [StarlarkFunctionArgument] = [
            .named(name: "name", value: name.toStarlark()),
            .named(name: "module_name", value: info.moduleName.toStarlark()),
            .named(name: "bundle_id", value: bundleId.toStarlark()),
            .named(name: "swift_version", value: info.swiftVersion.toStarlark()),
            .named(name: "link_dynamic", value: linkDynamic.toStarlark()),
            .named(name: "testonly", value: testonly.toStarlark()),
            .named(name: "infoplists", value: infoplists.map({ ":" + $0 }).toStarlark()),
            .named(name: "platforms", value: info.platforms.toStarlark()),
            .named(name: "srcs", value: sources.sourceFiles.toStarlark()),
            .named(name: "non_arc_srcs", value: sources.nonArcSourceFiles.toStarlark()),
            .named(name: "public_headers", value: sources.publicHeaders.toStarlark()),
            .named(name: "private_headers", value: sources.privateHeaders.toStarlark()),
            .named(name: "data", value: resources.packedToDataNode),
            .named(name: "deps", value: deps.toStarlark()),
            .named(name: "objc_defines", value: objcDefines),
            .named(name: "swift_defines", value: swiftDefines),
            .named(name: "sdk_dylibs", value: sdkDylibs.toStarlark()),
            .named(name: "sdk_frameworks", value: sdkFrameworks.toStarlark()),
            .named(name: "weak_sdk_frameworks", value: weakSdkFrameworks.toStarlark()),
            .named(name: "objc_copts", value: objcCopts.toStarlark()),
            .named(name: "swift_copts", value: swiftCopts.toStarlark()),
            .named(name: "linkopts", value: linkOpts.toStarlark()),
            .named(name: "xcconfig", value: xcconfig.toStarlark()),
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
            name: "apple_framework",
            arguments: lines
        )
    }
}

//
//  AppleFramework.swift
//  PodToBUILD
//
//  Created by Sergey Khliustin on 04.08.2022.
//

public enum AppleFrameworkConfigurableAddDeleteKeys: String {
    case sdkDylibs = "sdk_dylibs"
    case sdkFrameworks = "sdk_frameworks"
    case weakSdkFrameworks = "weak_sdk_frameworks"
    case deps = "deps"
}

public enum AppleFrameworkConfigurableOverriderKeys: String {
    case testonly = "testonly"
    case linkDynamic = "link_dynamic"
}

struct AppleFramework: BazelTarget, UserConfigurable {
    let loadNode = "load('@build_bazel_rules_ios//rules:framework.bzl', 'apple_framework')"

    let name: String

    let info: BaseAnalyzer.Result
    let sources: SourcesAnalyzer.Result
    let resources: ResourcesAnalyzer.Result
    let sdkDeps: SdkDependenciesAnalyzer.Result
    let vendoredDeps: VendoredDependenciesAnalyzer.Result
    let infoplists: [String]

    var deps: [String]
    var conditionalDeps: [String: [Arch]]

    let objcDefines: AttrSet<[String]>
    let swiftDefines: AttrSet<[String]>

    var sdkDylibs: [String]
    var sdkFrameworks: [String]
    var weakSdkFrameworks: [String]

    let objcCopts: [String]
    let swiftCopts: [String]
    let linkOpts: [String]

    var linkDynamic: Bool
    var testonly: Bool

    let xcconfig: [String: StarlarkNode]

    init(name: String,
         info: BaseAnalyzer.Result,
         sources: SourcesAnalyzer.Result,
         resources: ResourcesAnalyzer.Result,
         sdkDeps: SdkDependenciesAnalyzer.Result,
         vendoredDeps: VendoredDependenciesAnalyzer.Result,
         buildSettings: BuildSettingsAnalyzer.Result,
         infoplists: [String],
         deps: [String],
         conditionalDeps: [String: [Arch]] = [:]) {

        self.name = name

        self.info = info
        self.sources = sources
        self.resources = resources
        self.sdkDeps = sdkDeps
        self.vendoredDeps = vendoredDeps
        self.infoplists = infoplists

        self.deps = deps
        self.conditionalDeps = conditionalDeps

        self.swiftDefines = AttrSet(basic: ["COCOAPODS"])
        self.objcDefines = AttrSet(basic: ["COCOAPODS=1"])

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

    mutating func add(configurableKey: String, value: Any) {
        guard let key = AppleFrameworkConfigurableAddDeleteKeys(rawValue: configurableKey) else { return }
        switch key {
        case .sdkDylibs:
            if let value = value as? String {
                self.sdkDylibs.append(value)
            }
        case .sdkFrameworks:
            if let value = value as? String {
                self.sdkFrameworks.append(value)
            }
        case .weakSdkFrameworks:
            if let value = value as? String {
                self.weakSdkFrameworks.append(value)
            }
        case .deps:
            if let value = value as? String {
                self.deps.append(value)
            }
        }
    }

    mutating func delete(configurableKey: String, value: Any) {
        guard let key = AppleFrameworkConfigurableAddDeleteKeys(rawValue: configurableKey) else { return }
        switch key {
        case .sdkDylibs:
            if let value = value as? String {
                self.sdkDylibs.removeAll(where: { $0 == value })
            }
        case .sdkFrameworks:
            if let value = value as? String {
                self.sdkFrameworks.removeAll(where: { $0 == value })
            }
        case .weakSdkFrameworks:
            if let value = value as? String {
                self.weakSdkFrameworks.removeAll(where: { $0 == value })
            }
        case .deps:
            if let value = value as? String {
                self.deps = self.deps.filter({ $0 != value })
                self.conditionalDeps = self.conditionalDeps.filter({ $0.key != value })
            }
        }
    }

    mutating func override(configurableKey: String, value: Any) {
        guard let key = AppleFrameworkConfigurableOverriderKeys(rawValue: configurableKey) else { return }
        switch key {
        case .testonly:
            if let value = value as? String, let bool = Bool(value) {
                self.testonly = bool
            }
        case .linkDynamic:
            if let value = value as? String, let bool = Bool(value) {
                self.linkDynamic = bool
            }
        }
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
            .named(name: "public_headers", value: sources.publicHeaders.toStarlark()),
            .named(name: "private_headers", value: sources.privateHeaders.toStarlark()),
            .named(name: "data", value: packData()),
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

    private func packData() -> StarlarkNode {
        let data: StarlarkNode
        let resources = self.resources.resources
        let bundles = self.resources.precompiledBundles
        let resourcesNode = GlobNode(include: resources).toStarlark()
        let bundlesNode = bundles.toStarlark()

        switch (!resources.isEmpty, !bundles.isEmpty) {
        case (false, false):
            data = .empty
        case (true, false):
            data = resourcesNode
        case (false, true):
            data = bundlesNode
        case (true, true):
            data = StarlarkNode.expr(lhs: resourcesNode, op: "+", rhs: bundlesNode)
        }
        return data
    }
}

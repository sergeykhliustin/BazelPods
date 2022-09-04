//
//  AppleFramework.swift
//  PodToBUILD
//
//  Created by Sergey Khliustin on 04.08.2022.
//

struct AppleFramework: BazelTarget {
    let loadNode = "load('@build_bazel_rules_ios//rules:framework.bzl', 'apple_framework')"
    let name: String
    let version: String
    let sourceFiles: AttrSet<GlobNode>
    let moduleName: AttrSet<String>
    let platforms: [String: String]?
    let deps: AttrSet<[String]>

    // Resource files
    let resources: AttrSet<Set<String>>
    // .bundle in resource attribute
    let bundles: AttrSet<Set<String>>
    // resource_bundles attribute
    let resourceBundles: AttrSet<[String: Set<String>]>

    let externalName: String
    let objcDefines: AttrSet<[String]>
    let swiftDefines: AttrSet<[String]>
    let swiftVersion: AttrSet<String?>
    let xcconfig: [String: SkylarkNode]

    let publicHeaders: AttrSet<GlobNode>
    let privateHeaders: AttrSet<GlobNode>
    
    let sdkFrameworks: AttrSet<Set<String>>
    let weakSdkFrameworks: AttrSet<Set<String>>
    let sdkDylibs: AttrSet<Set<String>>
    let objcCopts: [String]
    let swiftCopts: [String]
    let linkOpts: [String]

    init(spec: PodSpec, subspecs: [PodSpec], deps: Set<String> = [], dataDeps: Set<String> = [], options: BuildOptions) {

        let podName = spec.name
        let name = podName

        self.name = name
        self.version = spec.version ?? "1.0"
        var platforms = spec.platforms ?? [:]
        if platforms["ios"] == nil {
            platforms["ios"] = options.iosPlatform
        }
        self.platforms = platforms

        self.externalName = spec.name

        let fallbackSpec = FallbackSpec(specs: [spec] + subspecs)

        self.moduleName = Self.resolveModuleName(spec: spec)

        sourceFiles = Self.getFilesNodes(from: spec, subspecs: subspecs, includesKeyPath: \.sourceFiles, excludesKeyPath: \.excludeFiles, fileTypes: AnyFileTypes, options: options)
        publicHeaders = Self.getFilesNodes(from: spec, subspecs: subspecs, includesKeyPath: \.publicHeaders, excludesKeyPath: \.privateHeaders, fileTypes: HeaderFileTypes, options: options)
        privateHeaders = Self.getFilesNodes(from: spec, subspecs: subspecs, includesKeyPath: \.privateHeaders, fileTypes: HeaderFileTypes, options: options)
        sdkDylibs = spec.collectAttribute(with: subspecs, keyPath: \.libraries)
        sdkFrameworks = spec.collectAttribute(with: subspecs, keyPath: \.frameworks)
        weakSdkFrameworks = spec.collectAttribute(with: subspecs, keyPath: \.weakFrameworks)
        let allPodSpecDeps = spec.collectAttribute(with: subspecs, keyPath: \.dependencies)
            .map({
                $0.map({
                    getDependencyName(options: options, podDepName: $0, podName: podName)
                }).filter({ !$0.hasPrefix(":") })
            })

        let depNames = deps.map { ":\($0)" }
        self.deps = AttrSet(basic: depNames) <> allPodSpecDeps

        self.swiftDefines = AttrSet(basic: ["COCOAPODS"])
        self.objcDefines = AttrSet(basic: ["COCOAPODS=1"])

        let resources = spec.collectAttribute(with: subspecs, keyPath: \.resources).unpackToMulti()

        self.resources = resources.map({ (value: Set<String>) -> Set<String> in
            value.filter({ !$0.hasSuffix(".bundle") })
        }).map(extractResources)

        self.bundles = resources.map({ (value: Set<String>) -> Set<String> in
            value.filter({ $0.hasSuffix(".bundle") })
        })

        self.resourceBundles = spec.collectAttribute(with: subspecs, keyPath: \.resourceBundles).map({ value -> [String: Set<String>] in
            var result = [String: Set<String>]()
            for key in value.keys {
                result[key] = Set(extractResources(patterns: value[key]!))
            }
            return result
        })


        self.swiftVersion = Self.resolveSwiftVersion(spec: fallbackSpec)

        let xcconfigParser = XCConfigParser(spec: spec, subspecs: subspecs, options: options)
        self.xcconfig = xcconfigParser.xcconfig

        self.objcCopts = xcconfigParser.objcCopts
        self.swiftCopts = xcconfigParser.swiftCopts
        self.linkOpts = xcconfigParser.linkOpts
    }

    func toSkylark() -> SkylarkNode {
        let basicSwiftDefines: SkylarkNode =
            .functionCall(name: "select",
                          arguments: [
                            .basic([
                                "//conditions:default": [
                                    "DEBUG",
                                ],
                            ].toSkylark())
                          ]
            )
        let basicObjcDefines: SkylarkNode =
            .functionCall(name: "select",
                          arguments: [
                            .basic([
                                ":release": [
                                    "POD_CONFIGURATION_RELEASE=1",
                                 ],
                                "//conditions:default": [
                                    "POD_CONFIGURATION_DEBUG=1",
                                    "DEBUG=1",
                                ],
                            ].toSkylark())
                          ])

        let swiftDefines = self.swiftDefines.toSkylark() .+. basicSwiftDefines
        let objcDefines = self.objcDefines.toSkylark() .+. basicObjcDefines

        let deps = deps.unpackToMulti().multi.ios.map {
            Set($0).sorted(by: (<))
        }

        // TODO: Make headers conditional
        let publicHeaders = (self.publicHeaders.multi.ios ?? .empty)
        let privateHeaders = self.privateHeaders.multi.ios ?? .empty

        // TODO: Make sources conditional
        let sourceFiles = self.sourceFiles.multi.ios.map({
            GlobNode(include: $0.include)
        }) ?? .empty

        let resourceBundles = (self.resourceBundles.multi.ios ?? [:]).mapValues({
            GlobNode(include: $0)
        })

        let moduleName = moduleName.unpackToMulti().multi.ios ?? ""
        let bundleId = "org.cocoapods.\(moduleName)"

        let lines: [SkylarkFunctionArgument] = [
            .named(name: "name", value: name.toSkylark()),
            .named(name: "module_name", value: moduleName.toSkylark()),
            .named(name: "bundle_id", value: bundleId.toSkylark()),
            .named(name: "swift_version", value: swiftVersion.toSkylark()),
            .named(name: "platforms", value: platforms.toSkylark()),
            .named(name: "srcs", value: sourceFiles.toSkylark()),
            .named(name: "public_headers", value: publicHeaders.toSkylark()),
            .named(name: "private_headers", value: privateHeaders.toSkylark()),
            .named(name: "resource_bundles", value: resourceBundles.toSkylark()),
            .named(name: "data", value: packData()),
            .named(name: "deps", value: deps.toSkylark()),
            .named(name: "sdk_frameworks", value: sdkFrameworks.toSkylark()),
            .named(name: "weak_sdk_frameworks", value: weakSdkFrameworks.toSkylark()),
            .named(name: "sdk_dylibs", value: sdkDylibs.toSkylark()),
            .named(name: "swift_defines", value: swiftDefines),
            .named(name: "objc_defines", value: objcDefines),
            .named(name: "swift_copts", value: swiftCopts.toSkylark()),
            .named(name: "objc_copts", value: objcCopts.toSkylark()),
            .named(name: "linkopts", value: linkOpts.toSkylark()),
            .named(name: "xcconfig", value: xcconfig.toSkylark()),
            .named(name: "visibility", value: ["//visibility:public"].toSkylark())
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

    private func packData() -> SkylarkNode {
        let data: SkylarkNode
        let resources = self.resources.multi.ios ?? []
        let bundles = self.bundles.multi.ios ?? []
        let resourcesNode = GlobNode(include: resources).toSkylark()
        let bundlesNode = bundles.toSkylark()

        switch (!resources.isEmpty, !bundles.isEmpty) {
        case (false, false):
            data = .empty
        case (true, false):
            data = resourcesNode
        case (false, true):
            data = bundlesNode
        case (true, true):
            data = SkylarkNode.expr(lhs: resourcesNode, op: "+", rhs: bundlesNode)
        }
        return data
    }

    private static func resolveModuleName(spec: PodSpec) -> AttrSet<String> {
        let transformer: (String) -> String = {
            $0.replacingOccurrences(of: "-", with: "_")
        }
        let moduleNameAttr = spec.attr(\.moduleName)
        if moduleNameAttr.isEmpty {
            return AttrSet(basic: transformer(spec.name))
        }
        return spec.attr(\.moduleName).map({
            if let value = $0, !value.isEmpty {
                return value
            }
            return transformer(spec.name)
        })

    }

    private static func getSourcesNodes(spec: PodSpec, deps: [PodSpec] = [], options: BuildOptions) -> AttrSet<GlobNode> {
        let (implFiles, implExcludes) = Self.getSources(spec: spec, deps: deps, options: options)

        return implFiles.zip(implExcludes).map {
            GlobNode(include: .left($0.first ?? Set()), exclude: .left($0.second ?? Set()))
        }
    }

    private static func getSources(spec: PodSpec, deps: [PodSpec] = [], options: BuildOptions) -> (includes:  AttrSet<Set<String>>, excludes:  AttrSet<Set<String>>) {
        let depsIncludes = AttrSet<Set<String>>(value: .empty)
        let depsExcludes = AttrSet<Set<String>>(value: .empty)

        let depsSources = deps.reduce((includes: depsIncludes, excludes: depsExcludes)) { partialResult, spec in
            let sources = Self.getSources(spec: spec, options: options)
            let includes = partialResult.includes <> sources.includes
            let excludes = partialResult.excludes <> sources.excludes
            return (includes, excludes)
        }

        let allSourceFiles = spec.attr(\.sourceFiles)
        let implFiles = extractFiles(fromPattern: allSourceFiles, includingFileTypes: AnyFileTypes, options: options)
            .unpackToMulti()
            .map { Set($0) }

        let allExcludes = spec.attr(\.excludeFiles)
        let implExcludes = extractFiles(fromPattern: allExcludes, includingFileTypes: AnyFileTypes, options: options)
            .unpackToMulti()
            .map { Set($0) }
        return (implFiles <> depsSources.includes, implExcludes <> depsSources.excludes)
    }

    private static func getFilesNodes(from spec: PodSpec,
                                      subspecs: [PodSpec] = [],
                                      includesKeyPath: KeyPath<PodSpecRepresentable, [String]>,
                                      excludesKeyPath: KeyPath<PodSpecRepresentable, [String]>? = nil,
                                      fileTypes: Set<String>,
                                      options: BuildOptions) -> AttrSet<GlobNode> {
        let (implFiles, implExcludes) = Self.getFiles(from: spec,
                                                      subspecs: subspecs,
                                                      includesKeyPath: includesKeyPath,
                                                      excludesKeyPath: excludesKeyPath,
                                                      fileTypes: fileTypes,
                                                      options: options)

        return implFiles.zip(implExcludes).map {
            GlobNode(include: .left($0.first ?? Set()), exclude: .left($0.second ?? Set()))
        }
    }

    private static func getFiles(from spec: PodSpec,
                                 subspecs: [PodSpec] = [],
                                 includesKeyPath: KeyPath<PodSpecRepresentable, [String]>,
                                 excludesKeyPath: KeyPath<PodSpecRepresentable, [String]>? = nil,
                                 fileTypes: Set<String>,
                                 options: BuildOptions) -> (includes: AttrSet<Set<String>>, excludes: AttrSet<Set<String>>) {
        let depsIncludes = AttrSet<Set<String>>(value: .empty)
        let depsExcludes = AttrSet<Set<String>>(value: .empty)

        let depsSources = subspecs.reduce((includes: depsIncludes, excludes: depsExcludes)) { partialResult, spec in
            let sources = Self.getFiles(from: spec, includesKeyPath: includesKeyPath, excludesKeyPath: excludesKeyPath, fileTypes: fileTypes, options: options)
            let includes = partialResult.includes <> sources.includes
            let excludes = partialResult.excludes <> sources.excludes
            return (includes, excludes)
        }

        let allFiles = spec.attr(includesKeyPath)
        let implFiles = extractFiles(fromPattern: allFiles, includingFileTypes: fileTypes, options: options)
            .unpackToMulti()
            .map { Set($0) }

        var implExcludes: AttrSet<Set<String>> = AttrSet.empty

        if let excludesKeyPath = excludesKeyPath {
            let allExcludes = spec.attr(excludesKeyPath)
            implExcludes = extractFiles(fromPattern: allExcludes, includingFileTypes: fileTypes, options: options)
                .unpackToMulti()
                .map { Set($0) }
        }

        return (implFiles <> depsSources.includes, implExcludes <> depsSources.excludes)
    }

    private static func resolveSwiftVersion(spec: FallbackSpec) -> AttrSet<String?> {
        return spec.attr(\.swiftVersions).map {
            if let versions = $0?.compactMap({ Double($0) }) {
                if versions.contains(where: { $0 >= 5.0 }) {
                    return "5"
                } else if versions.contains(where: { $0 >= 4.2 }) {
                    return "4.2"
                } else if !versions.isEmpty {
                    return "4"
                }
            }
            return nil
        }
    }
}

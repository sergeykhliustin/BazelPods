//
//  TestSpec.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 01.02.2024.
//

import Foundation

private enum Keys: String {
    case test_type
    case requires_app_host
    case app_host_name
    case info_plist
}

public final class TestSpec: TestSpecRepresentable {
    let name: String
    let ios: TestSpec?
    let osx: TestSpec?
    let tvos: TestSpec?
    let watchos: TestSpec?

    let version: String
    let moduleName: String?
    let platforms: [String: String]
    let swiftVersions: [String]?

    let sourceFiles: [String]
    let excludeFiles: [String]
    let publicHeaders: [String]
    let privateHeaders: [String]
    let requiresArc: Either<Bool, [String]>?
    let staticFramework: Bool

    let libraries: [String]
    let frameworks: [String]
    let weakFrameworks: [String]

    let resourceBundles: [String: [String]]
    let resources: [String]

    let dependencies: [String]

    let xcconfig: [String: String]
    let podTargetXcconfig: [String: String]
    let userTargetXcconfig: [String: String]

    let vendoredLibraries: [String]
    let vendoredFrameworks: [String]

    let infoPlist: [String: Any]?

    let testType: TestSpecTestType
    let requiresAppHost: Bool
    let appHostName: String?

    let launchArguments: [String]
    let environmentVariables: [String: String]

    init(JSONPodspec json: JSONDict, version: String) throws {
        self.version = version

        name = Self.name(json: json)
        ios = Self.ios(json: json, version: version)
        osx = Self.osx(json: json, version: version)
        tvos = Self.tvos(json: json, version: version)
        watchos = Self.watchos(json: json, version: version)
        moduleName = Self.moduleName(json: json)
        platforms = Self.platforms(json: json)
        swiftVersions = Self.swiftVersions(json: json)
        sourceFiles = Self.sourceFiles(json: json)
        excludeFiles = Self.excludeFiles(json: json)
        publicHeaders = Self.publicHeaders(json: json)
        privateHeaders = Self.privateHeaders(json: json)
        requiresArc = Self.requiresArc(json: json)
        staticFramework = Self.staticFramework(json: json)
        libraries = Self.libraries(json: json)
        frameworks = Self.frameworks(json: json)
        weakFrameworks = Self.weakFrameworks(json: json)
        resourceBundles = Self.resourceBundles(json: json)
        resources = Self.resources(json: json)
        dependencies = Self.dependencies(json: json)
        xcconfig = Self.xcconfig(json: json)
        podTargetXcconfig = Self.podTargetXcconfig(json: json)
        userTargetXcconfig = Self.userTargetXcconfig(json: json)
        vendoredLibraries = Self.vendoredLibraries(json: json)
        vendoredFrameworks = Self.vendoredFrameworks(json: json)
        infoPlist = Self.infoPlist(json: json)

        testType = (json[Keys.test_type.rawValue] as? String).flatMap({ TestSpecTestType(rawValue: $0) }) ?? .unit
        requiresAppHost = (json[Keys.requires_app_host.rawValue] as? Bool) ?? false
        appHostName = (json[Keys.app_host_name.rawValue] as? String)?.lastPath

        launchArguments = Self.launchArguments(json: json)
        environmentVariables = Self.environmentVariables(json: json)
    }
}

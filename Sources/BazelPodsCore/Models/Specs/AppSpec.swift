//
//  AppSpec.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 08.02.2024.
//

import Foundation

public final class AppSpec: AppSpecRepresentable {
    let name: String
    let ios: AppSpec?
    let osx: AppSpec?
    let tvos: AppSpec?
    let watchos: AppSpec?

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
    }
}

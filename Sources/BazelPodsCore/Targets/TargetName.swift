//
//  TargetName.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 08.02.2023.
//

import Foundation

private let SEPARATOR = "_"

struct TargetName {
    let platform: Platform
    let platformSuffix: Bool

    func base(_ baseName: String) -> String {
        return joined([
            baseName,
            platformString
        ])
    }

    func baseInfoplist(_ baseName: String) -> String {
        return joined([
            baseName,
            "InfoPlist",
            platformString
        ])
    }

    func bundle(_ baseName: String, bundle: String) -> String {
        return joined([
            baseName,
            bundle,
            "Bundle",
            platformString
        ])
    }

    func bundleInfoplist(_ baseName: String, bundle: String) -> String {
        return joined([
            baseName,
            bundle,
            "Bundle",
            "InfoPlist",
            platformString
        ])
    }

    func library(_ baseName: String, library: String) -> String {
        return joined([
            baseName,
            library,
            "VendoredLibrary",
            platformString
        ])
    }

    func framework(_ baseName: String, framework: String) -> String {
        return joined([
            baseName,
            framework,
            "VendoredFramework",
            platformString
        ])
    }

    func xcframework(_ baseName: String, xcframework: String) -> String {
        return joined([
            baseName,
            xcframework,
            "VendoredXCFramework",
            platformString
        ])
    }

    func podDependency(_ dep: String, options: BuildOptions) -> String {
        return "\(options.depsPrefix)/\(dep):\(base(dep))"
    }

    private var platformString: String {
        return platformSuffix ? platform.rawValue : ""
    }

    private func joined(_ strings: [String]) -> String {
        return strings
            .filter({ !$0.isEmpty })
            .joined(separator: SEPARATOR)
    }
}

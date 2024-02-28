//
//  VendoredDependenciesRepresentable.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 28.02.2024.
//

import Foundation

protocol VendoredDependenciesRepresentable: BaseRepresentable {
    var vendoredFrameworks: [String] { get }
    var vendoredLibraries: [String] { get }
}

private enum Keys: String {
    case vendored_frameworks
    case vendored_libraries
}

extension VendoredDependenciesRepresentable {
    static func vendoredFrameworks(json: JSONDict) -> [String] {
        return strings(fromJSON: json[Keys.vendored_frameworks.rawValue])
    }

    static func vendoredLibraries(json: JSONDict) -> [String] {
        return strings(fromJSON: json[Keys.vendored_libraries.rawValue])
    }
}

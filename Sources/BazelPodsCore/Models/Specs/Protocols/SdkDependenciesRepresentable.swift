//
//  SdkDependenciesRepresentable.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 02.02.2024.
//

import Foundation

protocol SdkDependenciesRepresentable: BaseRepresentable {
    var libraries: [String] { get }
    var frameworks: [String] { get }
    var weakFrameworks: [String] { get }
}

private enum Keys: String {
    case libraries
    case frameworks
    case weak_frameworks
}

extension SdkDependenciesRepresentable {
    static func libraries(json: JSONDict) -> [String] {
        return strings(fromJSON: json[Keys.libraries.rawValue])
    }

    static func frameworks(json: JSONDict) -> [String] {
        return strings(fromJSON: json[Keys.frameworks.rawValue])
    }

    static func weakFrameworks(json: JSONDict) -> [String] {
        return strings(fromJSON: json[Keys.weak_frameworks.rawValue])
    }
}

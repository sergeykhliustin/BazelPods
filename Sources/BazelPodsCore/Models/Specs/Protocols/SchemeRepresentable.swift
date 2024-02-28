//
//  SchemeRepresentable.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 27.02.2024.
//

import Foundation

protocol SchemeRepresentable: BaseRepresentable {
    var launchArguments: [String] { get }
    var environmentVariables: [String: String] { get }
}

private enum Keys: String {
    case scheme
    case launch_arguments
    case environment_variables
}

extension SchemeRepresentable {
    private static func scheme(json: JSONDict) -> JSONDict? {
        return json[Keys.scheme.rawValue] as? JSONDict
    }

    static func launchArguments(json: JSONDict) -> [String] {
        return (scheme(json: json))?[Keys.launch_arguments.rawValue] as? [String] ?? []
    }

    static func environmentVariables(json: JSONDict) -> [String: String] {
        return (scheme(json: json))?[Keys.environment_variables.rawValue] as? [String: String] ?? [:]
    }
}

//
//  PodDependenciesRepresentable.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 02.02.2024.
//

import Foundation

protocol PodDependenciesRepresentable: BaseRepresentable {
    var dependencies: [String] { get }
}

private enum Keys: String {
    case dependencies
}

extension PodDependenciesRepresentable {
    static func dependencies(json: JSONDict) -> [String] {
        ((json[Keys.dependencies.rawValue] as? JSONDict)?.keys).map(Array.init) ?? []
    }
}

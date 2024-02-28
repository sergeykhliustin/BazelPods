//
//  ResourcesRepresentable.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 02.02.2024.
//

import Foundation

protocol ResourcesRepresentable: BaseRepresentable {
    var resourceBundles: [String: [String]] { get }
    var resources: [String] { get }
}

private enum Keys: String {
    case resources
    case resource_bundles
}

extension ResourcesRepresentable {
    static func resources(json: JSONDict) -> [String] {
        strings(fromJSON: json[Keys.resources.rawValue])
    }

    static func resourceBundles(json: JSONDict) -> [String: [String]] {
        guard let resourceBundleMap = json[Keys.resource_bundles.rawValue] as? JSONDict else { return [:] }

        return Dictionary(tuples: resourceBundleMap.map { key, val in
            (key, strings(fromJSON: val))
        })
    }
}

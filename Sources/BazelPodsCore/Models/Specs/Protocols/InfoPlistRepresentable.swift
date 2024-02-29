//
//  InfoPlistRepresentable.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 08.02.2024.
//

import Foundation

protocol InfoPlistRepresentable: BaseRepresentable {
    var infoPlist: [String: Any]? { get }
}

private enum Keys: String {
    case info_plist
}

extension InfoPlistRepresentable {
    static func infoPlist(json: JSONDict) -> [String: Any]? {
        return json[Keys.info_plist.rawValue] as? [String: Any]
    }
}

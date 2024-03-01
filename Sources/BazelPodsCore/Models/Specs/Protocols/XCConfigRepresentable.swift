//
//  XCConfigRepresentable.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 08.02.2024.
//

import Foundation

protocol XCConfigRepresentable: BaseRepresentable {
    var podTargetXcconfig: [String: String] { get }
    var userTargetXcconfig: [String: String] { get }
    var xcconfig: [String: String] { get }
}

extension XCConfigRepresentable {
    var moduleName: String? {
        return podTargetXcconfig["SWIFT_MODULE_NAME"]
    }
}

private enum Keys: String {
    case pod_target_xcconfig
    case user_target_xcconfig
    case xcconfig
}

extension XCConfigRepresentable {
    static func podTargetXcconfig(json: JSONDict) -> [String: String] {
        return extractValue(fromJSON: json[Keys.pod_target_xcconfig.rawValue], default: [:])
    }

    static func userTargetXcconfig(json: JSONDict) -> [String: String] {
        return extractValue(fromJSON: json[Keys.user_target_xcconfig.rawValue], default: [:])
    }

    static func xcconfig(json: JSONDict) -> [String: String] {
        return extractValue(fromJSON: json[Keys.xcconfig.rawValue], default: [:])
    }
}

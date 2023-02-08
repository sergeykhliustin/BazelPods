//
//  RuleUtils.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 9/20/2018.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

import Foundation

public func replacePodsEnvVars(_ value: String, options: BuildOptions) -> String {
    let podDir = options.podsRoot
    let targetDir = options.podTargetSrcRoot
    return value
        .replacingOccurrences(of: "$(inherited)", with: "")
        .replacingOccurrences(of: "$(PODS_ROOT)", with: podDir)
        .replacingOccurrences(of: "${PODS_ROOT}", with: podDir)
        .replacingOccurrences(of: "$(PODS_TARGET_SRCROOT)", with: targetDir)
        .replacingOccurrences(of: "${PODS_TARGET_SRCROOT}", with: targetDir)
}

public func xcconfigSettingToList(_ value: String) -> [String] {
    return value
        .components(separatedBy: "=\"")
        .map {
            let components = $0.components(separatedBy: "\"")
            guard components.count == 2 else {
                return $0
            }
            let modifiedValue = [
                components.first?.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "",
                components.dropFirst().joined()
            ].joined(separator: "\\\"")
            return modifiedValue
        }
        .joined(separator: "=\\\"")
        .components(separatedBy: .whitespaces)
        .map { $0.removingPercentEncoding ?? "" }
        .map { $0.replacingOccurrences(of: "\"", with: "") }
        .map { $0.replacingOccurrences(of: "\\", with: "") }
        .filter({ $0 != "$(inherited)"})
        .filter({ !$0.isEmpty })
}

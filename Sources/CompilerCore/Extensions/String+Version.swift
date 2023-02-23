//
//  String+Version.swift
//  PodToBUILD
//
//  Created by Sergey Khliustin on 27.12.2022.
//

import Foundation

extension String {
    func compareVersion(_ withVersion: String) -> ComparisonResult {
        var components1 = self.components(separatedBy: ".")
        var components2 = withVersion.components(separatedBy: ".")
        while components1.count < components2.count {
            components1.append("0")
        }
        while components2.count < components1.count {
            components2.append("0")
        }
        let count = components1.count

        for i in 0..<count {
            let component1 = Int(components1[i]) ?? 0
            let component2 = Int(components2[i]) ?? 0
            if component1 != component2 {
                return component1 < component2 ? .orderedAscending : .orderedDescending
            }
        }

        return .orderedSame
    }
}

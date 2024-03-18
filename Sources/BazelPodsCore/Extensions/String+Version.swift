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

    var appleCompatibleVersion: String {
        // Regular expression pattern to find semantic versioning parts
        let pattern = #"^(\d+\.\d+\.\d+)"#

        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsVersion = self as NSString
        let matches = regex?.matches(in: self, options: [], range: NSRange(location: 0, length: nsVersion.length))

        if let match = matches?.first {
            // Extract the matched version part which excludes pre-release or build metadata
            let compatibleVersion = nsVersion.substring(with: match.range)
            return compatibleVersion
        }

        // Return the original string if no match is found, or pattern matching fails
        return self
    }
}

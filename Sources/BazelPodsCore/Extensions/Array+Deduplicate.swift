//
//  Array+Deduplicate.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 08.02.2023.
//

import Foundation

/// Remove duplicates from array with saving order
extension Array where Element: Hashable {
    func deduplicate() -> Self {
        var hash = Set<Element>()
        var result = [Element]()
        for element in self where !hash.contains(element) {
            hash.insert(element)
            result.append(element)
        }
        return result
    }
}

//
//  Set+Map.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 05.02.2023.
//

import Foundation

extension Set {
    func setmap<U>(transform: (Element) -> U) -> Set<U> {
        return Set<U>(self.lazy.map(transform))
    }
}

//
//  StarlarkConvertible.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/19/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation

// StarlarkConvertible is a higher level representation of types within Starlark
protocol StarlarkConvertible {
    func toStarlark() -> StarlarkNode
}

extension StarlarkNode: StarlarkConvertible {
    func toStarlark() -> StarlarkNode {
        return self
    }
}

extension StarlarkNode: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public init(stringLiteral value: String) {
        self = .string(value)
    }
    public init(unicodeScalarLiteral value: String) {
        self.init(stringLiteral: value)
    }
    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(stringLiteral: value)
    }
}

extension StarlarkNode: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension Bool: StarlarkConvertible {
    func toStarlark() -> StarlarkNode {
        return .bool(self)
    }
}

extension Int: StarlarkConvertible {
    func toStarlark() -> StarlarkNode {
        return .int(self)
    }
}

extension String: StarlarkConvertible {
    func toStarlark() -> StarlarkNode {
        return .string(self)
    }
}

extension Array: StarlarkConvertible where Element: StarlarkConvertible {
    func toStarlark() -> StarlarkNode {
        return .list(self.map { $0.toStarlark() })
    }
}

extension Optional: StarlarkConvertible where Wrapped: StarlarkConvertible {
    func toStarlark() -> StarlarkNode {
        switch self {
        case .none: return StarlarkNode.empty
        case .some(let x): return x.toStarlark()
        }
    }
}

extension Dictionary: StarlarkConvertible where Key == String, Value: StarlarkConvertible {
    func toStarlark() -> StarlarkNode {
        return .dict([:] <> self.map {
            return ($0.key, $0.value.toStarlark())
        })
    }
}

extension Set: StarlarkConvertible where Element: StarlarkConvertible, Element: Comparable {
    func toStarlark() -> StarlarkNode {
        return self.sorted().toStarlark()
    }
}

extension Either: StarlarkConvertible where T: StarlarkConvertible, U: StarlarkConvertible {
    func toStarlark() -> StarlarkNode {
        switch self {
        case .left(let value):
            return value.toStarlark()
        case .right(let value):
            return value.toStarlark()
        }
    }
}

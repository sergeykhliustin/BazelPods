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

extension Array: StarlarkConvertible {
    func toStarlark() -> StarlarkNode {
        return .list(self.map { x in (x as! StarlarkConvertible).toStarlark() })
    }
}

extension Optional: StarlarkConvertible {
    func toStarlark() -> StarlarkNode {
        switch self {
        case .none: return StarlarkNode.empty
        case .some(let x): return (x as! StarlarkConvertible).toStarlark()
        }
    }
}

extension Dictionary: StarlarkConvertible {
    func toStarlark() -> StarlarkNode {
        return .dict([:] <> self.map { kv in
            let key = kv.0 as! String
            let value = kv.1 as! StarlarkConvertible
            return (key, value.toStarlark())
        })
    }
}

extension Set: StarlarkConvertible {
    func toStarlark() -> StarlarkNode {
        // HACK: Huge hack, but fixing this for real would require major refactoring
        // ASSUMPTION: You're only calling Set.toStarlark on strings!!!
        // FIXME in Swift 4
        return self.map{ $0 as! String }.sorted().toStarlark()
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

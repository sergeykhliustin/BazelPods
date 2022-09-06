//
//  SkylarkConvertible.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/19/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation

// SkylarkConvertible is a higher level representation of types within Skylark
protocol SkylarkConvertible {
    func toSkylark() -> SkylarkNode
}

extension SkylarkNode: SkylarkConvertible {
    func toSkylark() -> SkylarkNode {
        return self
    }
}

extension SkylarkNode: ExpressibleByStringLiteral {
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

extension SkylarkNode: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension Int: SkylarkConvertible {
    func toSkylark() -> SkylarkNode {
        return .int(self)
    }
}

extension String: SkylarkConvertible {
    func toSkylark() -> SkylarkNode {
        return .string(self)
    }
}

extension Array: SkylarkConvertible {
    func toSkylark() -> SkylarkNode {
        return .list(self.map { x in (x as! SkylarkConvertible).toSkylark() })
    }
}

extension Optional: SkylarkConvertible {
    func toSkylark() -> SkylarkNode {
        switch self {
        case .none: return SkylarkNode.empty
        case .some(let x): return (x as! SkylarkConvertible).toSkylark()
        }
    }
}

extension Dictionary: SkylarkConvertible {
    func toSkylark() -> SkylarkNode {
        return .dict([:] <> self.map { kv in
            let key = kv.0 as! String
            let value = kv.1 as! SkylarkConvertible
            return (key, value.toSkylark())
        })
    }
}

extension Set: SkylarkConvertible {
    func toSkylark() -> SkylarkNode {
        // HACK: Huge hack, but fixing this for real would require major refactoring
        // ASSUMPTION: You're only calling Set.toSkylark on strings!!!
        // FIXME in Swift 4
        return self.map{ $0 as! String }.sorted().toSkylark()
    }
}

extension Either: SkylarkConvertible where T: SkylarkConvertible, U: SkylarkConvertible {
    func toSkylark() -> SkylarkNode {
        switch self {
        case .left(let value):
            return value.toSkylark()
        case .right(let value):
            return value.toSkylark()
        }
    }
}
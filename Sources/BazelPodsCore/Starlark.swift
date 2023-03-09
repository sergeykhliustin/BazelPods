//
//  Starlark.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/14/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation

public indirect enum StarlarkNode {
    /// A integer in Starlark.
    case int(Int)

    /// A Boolean in Starlark.
    case bool(Bool)

    /// A string in Starlark.
    /// @note The string value is enclosed within ""
    case string(String)

    /// A multiline string in Starlark.
    /// @note The string value enclosed within """ """
    case multiLineString(String)

    /// A list of any Starlark Types
    case list([StarlarkNode])

    /// A function call.
    /// Arguments may be either named or basic
    case functionCall(name: String, arguments: [StarlarkFunctionArgument])

    /// Arbitrary starlark code.
    /// This code is escaped and compiled directly as specifed in the string.
    /// Use this for code that needs to be evaluated.
    case starlark(String)

    /// A starlark dict
    case dict([String: StarlarkNode])

    /// An expression with a lhs and a rhs separated by an op
    case expr(lhs: StarlarkNode, op: String, rhs: StarlarkNode)

    /// Lines are a bunch of nodes that we will render as separate lines
    case lines([StarlarkNode])

    /// Flatten nested lines to a single array of lines
    func canonicalize() -> StarlarkNode {
        // at the inner layer we just strip the .lines
        func helper(inner: StarlarkNode) -> [StarlarkNode] {
            switch inner {
            case let .lines(nodes): return nodes
            case let other: return [other]
            }
        }

        // and at the top level we keep the .lines wrapper
        switch self {
        case let .lines(nodes): return .lines(nodes.flatMap(helper))
        case let other: return other
        }
    }
}

extension StarlarkNode: Monoid, EmptyAwareness {
    public static var empty: StarlarkNode { return .list([]) }

    // TODO(bkase): Annotate AttrSet with monoidal public struct wrapper to get around this hack
    /// WARNING: This doesn't obey the laws :(.
    public static func<>(lhs: StarlarkNode, rhs: StarlarkNode) -> StarlarkNode {
        return lhs .+. rhs
    }

    public var isEmpty: Bool {
        switch self {
        case let .list(xs): return xs.isEmpty
        case let .dict(dict): return dict.isEmpty
        case let .string(string): return string.isEmpty
        default: return false
        }
    }
}

// because it must be done
infix operator .+.: AdditionPrecedence
func .+.(lhs: StarlarkNode, rhs: StarlarkNode) -> StarlarkNode {
    switch (lhs, rhs) {
    case (.list(let l), .list(let r)): return .list(l + r)
    case (_, .list(let v)) where v.isEmpty: return lhs
    case (.list(let v), _) where v.isEmpty: return rhs
    default: return .expr(lhs: lhs, op: "+", rhs: rhs)
    }
}

infix operator .=.: AdditionPrecedence
func .=.(lhs: StarlarkNode, rhs: StarlarkNode) -> StarlarkNode {
    return .expr(lhs: lhs, op: "=", rhs: rhs)
}

public indirect enum StarlarkFunctionArgument {
    case basic(StarlarkNode)
    case named(name: String, value: StarlarkNode)
}

// MARK: - StarlarkCompiler

public struct StarlarkCompiler {
    let root: StarlarkNode
    let indent: Int
    private let whitespace: String

    public init(_ lines: [StarlarkNode]) {
        self.init(.lines(lines))
    }

    public init(_ root: StarlarkNode, indent: Int = 0) {
        self.root = root.canonicalize()
        self.indent = indent
        whitespace = StarlarkCompiler.white(indent: indent)
    }

    public func run() -> String {
        return compile(root)
    }

    private func compile(_ node: StarlarkNode) -> String {
        switch node {
        case let .int(value):
            return "\(value)"
        case let .bool(value):
            return value ? "True" : "False"
        case let .string(value):
            return "\"\(value)\""
        case let .multiLineString(value):
            return "\"\"\"\(value)\"\"\""
        case let .functionCall(call, arguments):
            let compiler = StarlarkCompiler(node, indent: indent + 2)
            return compiler.compile(call: call, arguments: arguments, closeParenWhitespace: whitespace)
        case let .starlark(value):
            return value
        case let .list(value):
            guard !value.isEmpty else { return "[]" }
            return "[\n" + value.map { node in
                "\(StarlarkCompiler.white(indent: indent + 2))\(compile(node))"
            }.joined(separator: ",\n") + "\n\(whitespace)]"
        case let .expr(lhs, op, rhs):
            return compile(lhs) + " \(op) " + compile(rhs)
        case let .dict(dict):
            guard !dict.isEmpty else { return "{}" }
            // Stabilize dict keys here. Other inputs are required to be stable.
            let sortedKeys = Array(dict.keys).sorted { $0 < $1 }
            let compiler = StarlarkCompiler(node, indent: indent + 2)
            return "{\n" + sortedKeys.compactMap { key in
                guard let val = dict[key] else { return nil }
                return "\(StarlarkCompiler.white(indent: indent + 2))\(compiler.compile(.string(key))): \(compiler.compile(val))"
            }.joined(separator: ",\n") + "\n\(whitespace)}"
        case let .lines(lines):
            return lines.map(compile).joined(separator: "\n")
        }
    }

    // MARK: - Private

    private func compile(call: String, arguments: [StarlarkFunctionArgument], closeParenWhitespace: String) -> String {
        var buildFile = ""
        buildFile += "\(call)(\n"
        for (idx, argument) in arguments.enumerated() {
            let comma = idx == arguments.count - 1 ? "" : ","
            switch argument {
            case let .named(name, argValue):
                buildFile += "\(whitespace)\(name) = \(compile(argValue))\(comma)\n"
            case let .basic(argValue):
                buildFile += "\(whitespace)\(compile(argValue))\(comma)\n"
            }
        }
        buildFile += "\(closeParenWhitespace))"
        return buildFile
    }

    private static func white(indent: Int) -> String {
        precondition(indent >= 0)

        if indent == 0 {
            return ""
        }

        var white = ""
        for _ in 1 ... indent {
            white += " "
        }
        return white
    }
}

//
//  GlobNode.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 05/21/18.
//  Copyright © 2020 Pinterest Inc. All rights reserved.
//

import Foundation

public struct GlobNodeV2: StarlarkConvertible {
    // Bazel Glob function: glob(include, exclude=[], exclude_directories=1)
    public let include: [String]
    public let exclude: [String]
    public let excludeDirectories: Bool = true
    static let emptyArg: [String] = []

    public init(include: [String] = [], exclude: [String] = []) {
        self.include = include.sorted()
        self.exclude = exclude.sorted()
    }

    func map(_ transform: (String) -> String) -> GlobNodeV2 {
        return GlobNodeV2(include: include.map(transform), exclude: exclude.map(transform))
    }

    func absolutePaths(_ options: BuildOptions) -> GlobNodeV2 {
        return map({ options.absolutePath(from: $0) })
    }

    public func toStarlark() -> StarlarkNode {
        // An empty glob doesn't need to be rendered
        guard isEmpty == false else {
            return .empty
        }

        let include = self.include
        let exclude = self.exclude
        let includeArgs: [StarlarkFunctionArgument] = [
            .basic(include.toStarlark())
        ]

        // If there's no excludes omit the argument
        let excludeArgs: [StarlarkFunctionArgument] = exclude.isEmpty ? [] : [
            .named(name: "exclude", value: exclude.toStarlark())
        ]

        // Omit the default argument for exclude_directories
        let dirArgs: [StarlarkFunctionArgument] = self.excludeDirectories ? [] : [
            .named(name: "exclude_directories",
                   value: .int(self.excludeDirectories ? 1 : 0))
        ]

        return .functionCall(name: "glob",
                arguments: includeArgs + excludeArgs + dirArgs)
    }
}

extension GlobNodeV2: Equatable {
    public static func == (lhs: GlobNodeV2, rhs: GlobNodeV2) -> Bool {
        return lhs.include == rhs.include
            && lhs.exclude == rhs.exclude
    }
}

extension GlobNodeV2: EmptyAwareness {
    public var isEmpty: Bool {
        // If the include is the same as the exclude then it's empty
        return self.include.isEmpty || self.include == self.exclude
    }

    public static var empty: GlobNodeV2 {
        return GlobNodeV2(include: [String]())
    }
}

extension GlobNodeV2: Monoid {
    public static func <> (lhs: GlobNodeV2, rhs: GlobNodeV2) -> GlobNodeV2 {
        return GlobNodeV2(include: lhs.include <> rhs.include, exclude: lhs.exclude <> rhs.exclude)
    }
}

extension GlobNodeV2 {
    /// Evaluates the glob for all the sources on disk
    public func sourcesOnDisk(_ options: BuildOptions) -> Set<String> {
        let absoluteSelf = self.absolutePaths(options)
        let includedFiles = absoluteSelf.include.reduce(into: Set<String>()) { accum, next in
            podGlob(pattern: next).forEach { accum.insert($0) }
        }

        let excludedFiles = absoluteSelf.exclude.reduce(into: Set<String>()) { accum, next in
            podGlob(pattern: next).forEach { accum.insert($0) }
        }
        return includedFiles.subtracting(excludedFiles)
    }

    func hasSourcesOnDisk(_ options: BuildOptions) -> Bool {
        return sourcesOnDisk(options).count > 0
    }
}

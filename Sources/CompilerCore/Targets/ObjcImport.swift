//
//  ObjcImport.swift
//  BazelPods
//
//  Created by Sergey Khliustin on 27.08.2022.
//

import Foundation

// https://bazel.build/versions/master/docs/be/objective-c.html#objc_import
struct ObjcImport: BazelTarget {
    let loadNode = ""
    let name: String // A unique name for this rule.
    let library: String // The list of .a files provided to Objective-C targets that depend on this target.

    func toStarlark() -> StarlarkNode {
        return StarlarkNode.functionCall(
                name: "objc_import",
                arguments: [
                    .named(name: "name", value: name.toStarlark()),
                    .named(name: "archives", value: [library].toStarlark())
                ]
        )
    }
}

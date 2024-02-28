//
//  AppHostObjcLibrary.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 28.02.2024.
//

import Foundation

struct AppHostObjcLibrary: BazelTarget {
    let loadNode: String = ""
    let name: String
    let mainM: String

    func toStarlark() -> StarlarkNode {
        let lines: [StarlarkFunctionArgument] = [
            .named(name: "name", value: name.toStarlark()),
            .named(name: "srcs", value: [":" + mainM].toStarlark())
        ]
        return .functionCall(
            name: "objc_library",
            arguments: lines
        )
    }
}

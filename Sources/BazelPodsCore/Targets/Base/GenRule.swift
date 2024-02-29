//
//  GenRule.swift
//  PodToBUILD
//
//  Created by Sergey Khliustin on 02.09.2022.
//

import Foundation

class GenRule: BazelTarget {
    let loadNode = ""
    let name: String
    let srcs: [String]
    let outs: [String]
    let cmd: String

    init(name: String,
         srcs: [String] = [],
         outs: [String] = [],
         cmd: String = "") {
        self.name = name
        self.srcs = srcs
        self.outs = outs
        self.cmd = cmd
    }

    convenience init(name: String,
                     fileName: String? = nil,
                     fileExtension: String,
                     fileContent: String) {
        self.init(name: name, outs: ["\(fileName ?? name).\(fileExtension)"], cmd: "cat <<EOF > $@\n\(fileContent)\nEOF")
    }

    func toStarlark() -> StarlarkNode {
        return .functionCall(
            name: "genrule",
            arguments: [
                .named(name: "name", value: name.toStarlark()),
                .named(name: "srcs", value: srcs.toStarlark()),
                .named(name: "outs", value: outs.toStarlark()),
                .named(name: "cmd", value: .multiLineString(cmd))
            ])
    }
}

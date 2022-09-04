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

    init(name: String, srcs: [String] = [], outs: [String] = [], cmd: String = "") {
        self.name = name
        self.srcs = srcs
        self.outs = outs
        self.cmd = cmd
    }

    func toSkylark() -> SkylarkNode {
        return .functionCall(
            name: "genrule",
            arguments: [
                .named(name: "name", value: name.toSkylark()),
                .named(name: "srcs", value: srcs.toSkylark()),
                .named(name: "outs", value: outs.toSkylark()),
                .named(name: "cmd", value: .multiLineString(cmd))
            ])
    }
}

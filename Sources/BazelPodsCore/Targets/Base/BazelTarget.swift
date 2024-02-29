//
//  BazelTarget.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 10/17/2018.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

/// Law: Names must be valid bazel names; see the spec
protocol BazelTarget: StarlarkConvertible {
    var loadNode: String { get }
    var name: String { get }
}

extension BazelTarget {
    func makeDeps(deps: [String], conditionalDeps: [String: [Arch]]) -> StarlarkNode {
        let baseDeps = deps.map({ !$0.hasPrefix("/") ? ":" + $0 : $0 })
        var conditionalDepsMap = conditionalDeps.reduce([String: [String]]()) { partialResult, element in
            var result = partialResult
            element.value.forEach({
                let conditon = ":" + $0.rawValue
                let name = ":" + element.key
                var arr = result[conditon] ?? []
                arr.append(name)
                result[conditon] = arr
            })
            return result
        }.mapValues({ $0.sorted(by: <) })

        let deps: StarlarkNode
        if conditionalDepsMap.isEmpty {
            deps = baseDeps.toStarlark()
        } else {
            conditionalDepsMap["//conditions:default"] = []
            let conditionalDeps: StarlarkNode =
                .functionCall(name: "select",
                              arguments: [
                                .basic(conditionalDepsMap.toStarlark())
                              ])
            if baseDeps.isEmpty {
                deps = conditionalDeps
            } else {
                deps = .expr(lhs: baseDeps.toStarlark(), op: "+", rhs: conditionalDeps)
            }
        }
        return deps
    }
}

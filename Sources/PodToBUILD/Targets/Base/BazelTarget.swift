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

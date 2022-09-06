//
//  StarlarkConvertibleTransform.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 5/2/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation

protocol StarlarkConvertibleTransform {
    /// Apply a transform to starlark convertibles
    static func transform(convertibles: [BazelTarget], options: BuildOptions, podSpec: PodSpec) -> [BazelTarget]
}

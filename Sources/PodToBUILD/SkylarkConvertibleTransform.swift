//
//  SkylarkConvertibleTransform.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 5/2/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation

protocol SkylarkConvertibleTransform {
    /// Apply a transform to skylark convertibles
    static func transform(convertibles: [BazelTarget], options: BuildOptions, podSpec: PodSpec) -> [BazelTarget]
}
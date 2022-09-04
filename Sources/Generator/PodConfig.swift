//
//  PodConfig.swift
//  PodToBUILD
//
//  Created by Sergey Khliustin on 25.08.2022.
//

import Foundation

struct PodConfig: Decodable {
    let name: String
    let podspec: String
    let development: Bool
}

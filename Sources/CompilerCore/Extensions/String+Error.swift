//
//  String+Path.swift
//  BazelPods
//
//  Created by Sergey Khliustin on 05.09.2022.
//

import Foundation

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

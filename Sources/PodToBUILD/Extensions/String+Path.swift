//
//  String+Path.swift
//  BazelPods
//
//  Created by Sergey Khliustin on 05.09.2022.
//

import Foundation

public extension String {
    func appendingPath(_ str: String) -> String {
        return (self as NSString).appendingPathComponent(str)
    }

    var lastPath: String {
        return (self as NSString).lastPathComponent
    }

    var pathExtenstion: String {
        return (self as NSString).pathExtension
    }

    var deletingLastPath: String {
        return (self as NSString).deletingLastPathComponent
    }
}

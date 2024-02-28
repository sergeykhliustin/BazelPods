//
//  SourceFilesRepresentable.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 02.02.2024.
//

import Foundation

protocol SourceFilesRepresentable: BaseRepresentable {
    var sourceFiles: [String] { get }
    var excludeFiles: [String] { get }
    var publicHeaders: [String] { get }
    var privateHeaders: [String] { get }
    var requiresArc: Either<Bool, [String]>? { get }
    var staticFramework: Bool { get }
}

private enum Keys: String {
    case source_files
    case exclude_files
    case public_header_files
    case private_header_files
    case requires_arc
    case static_framework
}

extension SourceFilesRepresentable {
    static func sourceFiles(json: JSONDict) -> [String] {
        return strings(fromJSON: json[Keys.source_files.rawValue]).map({
            $0.hasSuffix("/") ? String($0.dropLast()) : $0
        })
    }

    static func excludeFiles(json: JSONDict) -> [String] {
        return strings(fromJSON: json[Keys.exclude_files.rawValue])
    }

    static func publicHeaders(json: JSONDict) -> [String] {
        return strings(fromJSON: json[Keys.public_header_files.rawValue])
    }

    static func privateHeaders(json: JSONDict) -> [String] {
        return strings(fromJSON: json[Keys.private_header_files.rawValue])
    }

    static func requiresArc(json: JSONDict) -> Either<Bool, [String]>? {
        if let bool = json[Keys.requires_arc.rawValue] as? Bool {
            return .left(bool)
        }
        return stringsStrict(fromJSON: json[Keys.requires_arc.rawValue]).map({ .right($0) })
    }

    static func staticFramework(json: JSONDict) -> Bool {
        return json[Keys.static_framework.rawValue] as? Bool ?? false
    }
}

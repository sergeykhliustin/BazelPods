//
//  BaseRepresentable.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 02.02.2024.
//

import Foundation

protocol BaseRepresentable {
    var name: String { get }
    var ios: Self? { get }
    var osx: Self? { get }
    var tvos: Self? { get }
    var watchos: Self? { get }

    init(JSONPodspec json: JSONDict, version: String) throws
}

private enum Keys: String {
    case name
    case ios
    case osx
    case tvos
    case watchos
}

extension BaseRepresentable {
    static func name(json: JSONDict) -> String {
        // name can be empty for platform specific (ios, macos, etc)
        return extractValue(fromJSON: json[Keys.name.rawValue], default: "")
    }

    static func ios(json: JSONDict, version: String) -> Self? {
        return (json[Keys.ios.rawValue] as? JSONDict).flatMap({ try? Self(JSONPodspec: $0, version: version) })
    }

    static func osx(json: JSONDict, version: String) -> Self? {
        return (json[Keys.osx.rawValue] as? JSONDict).flatMap({ try? Self(JSONPodspec: $0, version: version) })
    }

    static func tvos(json: JSONDict, version: String) -> Self? {
        return (json[Keys.tvos.rawValue] as? JSONDict).flatMap({ try? Self(JSONPodspec: $0, version: version) })
    }

    static func watchos(json: JSONDict, version: String) -> Self? {
        return (json[Keys.watchos.rawValue] as? JSONDict).flatMap({ try? Self(JSONPodspec: $0, version: version) })
    }
}

extension BaseRepresentable {
    // for extracting attr sets
    // The key reason that we have this code is to:
    // - merge the spec.ios.attr spec.attr
    func getAttrSet<T>(spec: Self, keyPath: KeyPath<Self, T>) -> AttrSet<T> {
        let value = spec[keyPath: keyPath]
        return AttrSet(basic: value) <> AttrSet(multi: MultiPlatform(
            ios: spec.ios?[keyPath: keyPath],
            osx: spec.osx?[keyPath: keyPath],
            watchos: spec.watchos?[keyPath: keyPath],
            tvos: spec.tvos?[keyPath: keyPath])
        )
    }

    func attr<T>(_ keyPath: KeyPath<Self, T>) -> AttrSet<T> {
        return getAttrSet(spec: self, keyPath: keyPath)
    }

    func collectAttribute(
        with subspecs: [Self],
        keyPath: KeyPath<Self, [String]>)
    -> AttrSet<[String]> {
        return (subspecs + [self])
            .reduce(into: AttrSet<Set<String>>.empty) { partialResult, spec in
                partialResult = partialResult <> spec.attr(keyPath).unpackToMulti().map({ Set($0) })
            }
            .map({ $0.sorted() })
    }

    func collectAttribute(
        with subspecs: [Self] = [],
        keyPath: KeyPath<Self, [String: [String]]>) -> AttrSet<[String: [String]]> {
        return (subspecs + [self])
            .reduce(into: AttrSet<[String: [String]]>.empty) { partialResult, spec in
                partialResult = partialResult.zip(spec.attr(keyPath).unpackToMulti()).map({
                    ($0.first ?? [:]) <+> ($0.second ?? [:])
                })
            }
    }

    func collectAttribute(
        with subspecs: [Self] = [],
        keyPath: KeyPath<Self, [String: String]>)
    -> AttrSet<[String: String]> {
        return (subspecs + [self])
            .reduce(into: AttrSet<[String: String]>.empty) { partialResult, spec in
                partialResult = partialResult.zip(spec.attr(keyPath).unpackToMulti()).map({
                    if let second = $0.second {
                        return ($0.first ?? [:]) <> second
                    } else {
                        return $0.first ?? [:]
                    }
                })
            }
    }
}

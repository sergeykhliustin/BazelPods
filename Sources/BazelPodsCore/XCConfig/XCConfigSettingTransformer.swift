//
//  XCConfigSettingTransformer.swift
//  BazelPods
//
//  Created by Sergey Khliustin on 02.09.2022.
//

import Foundation

protocol XCConfigSettingTransformer {
    var key: String { get }
}

protocol SwiftCoptsProvider {
    func swiftCopts(_ value: String) -> [String]
}

protocol ObjcCoptsProvider {
    func objcCopts(_ value: String) -> [String]
}

protocol LinkOptsProvider {
    func linkOpts(_ value: String) -> [String]
}

protocol ObjcDefinesProvider {
    func objcDefines(_ value: String) -> [String]
}

protocol CCCOptsProvider {
    func cccOpts(_ value: String) -> [String]
}

struct HeaderSearchPathTransformer: XCConfigSettingTransformer,
                                    SwiftCoptsProvider,
                                    ObjcCoptsProvider {
    let key = "HEADER_SEARCH_PATHS"

    func swiftCopts(_ value: String) -> [String] {
        return xcconfigSettingToList(value)
            .reduce([String]()) { partialResult, path in
                return partialResult + [
                    "-Xcc", "-I\(path.replacingOccurrences(of: "\"", with: ""))"
                ]
            }
    }

    func objcCopts(_ value: String) -> [String] {
        return xcconfigSettingToList(value)
            .map({ "-I\($0.replacingOccurrences(of: "\"", with: ""))" })
    }
}

struct UserHeaderSearchPathTransformer: XCConfigSettingTransformer,
                                    SwiftCoptsProvider,
                                    ObjcCoptsProvider {
    let key = "USER_HEADER_SEARCH_PATHS"

    func swiftCopts(_ value: String) -> [String] {
        return xcconfigSettingToList(value)
            .reduce([String]()) { partialResult, path in
                return partialResult + [
                    "-Xcc", "-I\(path.replacingOccurrences(of: "\"", with: ""))"
                ]
            }
    }

    func objcCopts(_ value: String) -> [String] {
        return xcconfigSettingToList(value)
            .map({ "-I\($0.replacingOccurrences(of: "\"", with: ""))" })
    }
}

struct ApplicationExtensionAPIOnlyTransformer: XCConfigSettingTransformer,
                                               SwiftCoptsProvider,
                                               ObjcCoptsProvider {
    let key = "APPLICATION_EXTENSION_API_ONLY"

    func swiftCopts(_ value: String) -> [String] {
        return value.lowercased() == "yes" ? ["-application-extension"] : []
    }

    func objcCopts(_ value: String) -> [String] {
        return value.lowercased() == "yes" ? ["-fapplication-extension"] : []
    }
}

struct LinkOptsListTransformer: XCConfigSettingTransformer,
                                LinkOptsProvider {
    let key: String
    init(_ key: String) {
        self.key = key
    }

    func linkOpts(_ value: String) -> [String] {
        return xcconfigSettingToList(value)
    }
}

struct ObjCOptsListTransformer: XCConfigSettingTransformer,
                                ObjcCoptsProvider {
    let key: String
    init(_ key: String) {
        self.key = key
    }

    func objcCopts(_ value: String) -> [String] {
        return xcconfigSettingToList(value)
    }
}

struct SwiftOptsListTransformer: XCConfigSettingTransformer,
                                 SwiftCoptsProvider {
    let key: String
    init(_ key: String) {
        self.key = key
    }

    func swiftCopts(_ value: String) -> [String] {
        return xcconfigSettingToList(value)
    }
}

struct ObjcDefinesListTransformer: XCConfigSettingTransformer,
                                   ObjcDefinesProvider {
    let key: String
    init(_ key: String) {
        self.key = key
    }

    func objcDefines(_ value: String) -> [String] {
        return xcconfigSettingToList(value)
    }
}

struct CLANG_CXX_LANGUAGE_STANDARD_Transformer: XCConfigSettingTransformer, CCCOptsProvider {
    let key = "CLANG_CXX_LANGUAGE_STANDARD"

    func cccOpts(_ value: String) -> [String] {
        return ["-std=\(value)"]
    }
}

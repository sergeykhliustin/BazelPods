//
//  UserOption.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 15.02.2023.
//

import Foundation

let PLATFORM_PREFIX = "platform_"

private extension String {
    var trim: String {
        return trimmingCharacters(in: .whitespaces)
    }
}

private extension Array where Element == String {
    var trim: Self {
        return map({ $0.trim }).filter({ !$0.isEmpty })
    }
}

public struct UserOption {
    public let name: String
    public let opt: Opt
    public let attribute: Attribute
    public let platform: Platform?

    public enum Opt: String, CaseIterable {
        static let regex = "[+\\-:]="
        case append = "+="
        case delete = "-="
        case replace = ":="

        public var description: String {
            switch self {
            case .append:
                return "append"
            case .delete:
                return "delete"
            case .replace:
                return "replace"
            }
        }
    }
    public enum Attribute {
        case sdk_frameworks([String])
        case sdk_dylibs([String])
        case weak_sdk_frameworks([String])
        case vendored_libraries([String])
        case vendored_frameworks([String])
        case vendored_xcframeworks([String])
        case testonly(Bool)
        case link_dynamic(Bool)
        case runner(String)
        case test_host(String)
    }
    public enum KeyPath: String, CaseIterable {
        case sdk_frameworks
        case sdk_dylibs
        case weak_sdk_frameworks
        case vendored_libraries
        case vendored_frameworks
        case vendored_xcframeworks
        case testonly
        case link_dynamic
        case runner
        case test_host
    }

    public init?(_ string: String) {
        guard
            let regex = try? NSRegularExpression(pattern: Opt.regex)
        else {
            log_error("internal error")
            return nil
        }
        let matches = regex.matches(in: string)
        guard
            matches.count == 1,
            let optString = matches.first,
            let opt = Opt(rawValue: optString)
        else {
            log_warning("Incorrect option: \(string). Skipping...")
            return nil
        }
        let components = string
            .components(separatedBy: opt.rawValue)
        var leftPart = components[0].components(separatedBy: ".").trim
        guard leftPart.count > 1 else {
            log_error("Incorrect option: \(string). Skipping...")
            return nil
        }
        guard
            let keyPathString = leftPart.last,
            let keyPath = KeyPath(rawValue: keyPathString)
        else {
            log_error("Unsupported keyPath: \(leftPart.last ?? ""). Skipping...")
            return nil
        }
        leftPart.removeLast()
        let platform: Platform?
        if
            leftPart.count > 1,
            let last = leftPart.last,
            last.hasPrefix(PLATFORM_PREFIX),
            let platfromValue = Platform(rawValue: last.deletingPrefix(PLATFORM_PREFIX)) {
            platform = platfromValue
            leftPart.removeLast()
        } else {
            platform = nil
        }
        let name = leftPart.joined()

        let value = components[1].components(separatedBy: ",").trim

        let attribute: Attribute
        switch keyPath {
        case .sdk_frameworks:
            attribute = .sdk_frameworks(value)
        case .sdk_dylibs:
            attribute = .sdk_dylibs(value)
        case .weak_sdk_frameworks:
            attribute = .weak_sdk_frameworks(value)
        case .vendored_libraries:
            guard opt == .delete else {
                log_error("Incorrect option \(string). 'vendored_libraries' supports only \(Opt.delete.rawValue) operator. Skipping...")
                return nil
            }
            attribute = .vendored_libraries(value)
        case .vendored_frameworks:
            guard opt == .delete else {
                log_error("Incorrect option \(string). 'vendored_frameworks' supports only \(Opt.delete.rawValue) operator. Skipping...")
                return nil
            }
            attribute = .vendored_frameworks(value)
        case .vendored_xcframeworks:
            guard opt == .delete else {
                log_error("Incorrect option \(string). 'vendored_xcframeworks' supports only \(Opt.delete.rawValue) operator. Skipping...")
                return nil
            }
            attribute = .vendored_xcframeworks(value)
        case .testonly:
            guard opt == .replace else {
                log_error("Incorrect option \(string). 'testonly' supports only \(Opt.replace.rawValue) operator. Skipping...")
                return nil
            }
            guard
                value.count == 1,
                let last = value.last?.trim,
                let bool = Bool(last)
            else {
                log_error("Incorrect value for \(string). Should be true or false. Skipping...")
                return nil
            }
            attribute = .testonly(bool)
        case .link_dynamic:
            guard opt == .replace else {
                log_error("Incorrect option for \(string). 'link_dynamic' supports only \(Opt.replace.rawValue) operator. Skipping...")
                return nil
            }
            guard
                value.count == 1,
                let last = value.last?.trim,
                let bool = Bool(last)
            else {
                log_error("Incorrect value \(string). Should be true or false. Skipping...")
                return nil
            }
            attribute = .link_dynamic(bool)
        case .runner:
            guard opt == .replace else {
                log_error("Incorrect option for \(string). '\(keyPath)' supports only \(Opt.replace.rawValue) operator. Skipping...")
                return nil
            }
            guard
                value.count == 1,
                let last = value.last?.trim
            else {
                log_error("Incorrect value for \(string). Should be correct Bazel target label. Skipping...")
                return nil
            }
            attribute = .runner(last)
        case .test_host:
            guard opt == .replace else {
                log_error("Incorrect option for \(string). '\(keyPath)' supports only \(Opt.replace.rawValue) operator. Skipping...")
                return nil
            }
            guard
                value.count == 1,
                let last = value.last?.trim
            else {
                log_error("Incorrect value for \(string). Should be correct Bazel target label. Skipping...")
                return nil
            }
            attribute = .test_host(last)
        }
        self.name = name
        self.opt = opt
        self.attribute = attribute
        self.platform = platform
    }
}

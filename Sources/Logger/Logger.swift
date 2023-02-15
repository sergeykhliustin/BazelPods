//
//  Logger.swift
//  Logger
//
//  Created by Sergey Khliustin on 02.02.2023.
//

import Foundation

public enum LogLevel: String, CaseIterable {
    case debug
    case info
    case warning
    case error
    case none

    var level: Int {
        switch self {
        case .debug:
            return 0
        case .info:
            return 1
        case .warning:
            return 2
        case .error:
            return 3
        case .none:
            return 4
        }
    }
}

private extension LogLevel {
    var string: String {
        switch self {
        case .debug:
            return "🔨debug:"
        case .info:
            return "info:"
        case .warning:
            return "warning:"
        case .error:
            return "error:"
        case .none:
            return ""
        }
    }

    var terminalColor: String {
        switch self {
        case .debug:
            return "[1;34m" // blue
        case .info:
            return "[32m" // green
        case .warning:
            return "[33m" // yellow
        case .error:
            return "[31m" // red
        case .none:
            return ""
        }
    }

    var coloredString: String {
        let reset = "[0m"
        let escape = "\u{001b}"
        return escape + terminalColor + string + escape + reset
    }
}

public protocol LoggerProtocol: AnyObject {
    func log_debug(file: StaticString, function: StaticString, line: Int, _ message: @autoclosure () -> Any)
    func log_info(_ message: @autoclosure () -> Any)
    func log_warning(_ message: @autoclosure () -> Any)
    func log_error(_ message: @autoclosure () -> Any)
    var prefix: String? { get set }
    var colors: Bool { get set }
    var level: LogLevel { get set }
}

public class DefaultLogger: LoggerProtocol {
    public init() {}

    public var prefix: String?
    public var colors: Bool = false
    public var level: LogLevel = .info

    public func log_debug(file: StaticString = #file, function: StaticString = #function, line: Int = #line, _ message: @autoclosure () -> Any) {
        let file = ("\(file)" as NSString).lastPathComponent
        log(.debug, message: ["\(file):\(line)", "\(message())"].joined(separator: ": "))
    }

    public func log_info(_ message: @autoclosure () -> Any) {
        log(.info, message: message())
    }

    public func log_warning(_ message: @autoclosure () -> Any) {
        log(.warning, message: message())
    }

    public func log_error(_ message: @autoclosure () -> Any) {
        log(.error, message: message())
    }

    func log(_ level: LogLevel, message: @autoclosure () -> Any) {
        guard level.level >= self.level.level else { return }
        var result = ""
        if colors {
            if let prefix {
                result += "[\u{001b}[35m\(prefix)\u{001b}[0m] "
            }
            result += level.coloredString
        } else {
            if let prefix {
                result += "[\(prefix)] "
            }
            result += level.string
        }
        result += " "
        result += "\(message())"
        print(result)
    }
}

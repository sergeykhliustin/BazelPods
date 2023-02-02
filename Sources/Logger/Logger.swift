//
//  Logger.swift
//  Logger
//
//  Created by Sergey Khliustin on 02.02.2023.
//

import Foundation

public enum LogLevel: Int {
    case debug = 0
    case info
    case warning
    case error
}

private extension LogLevel {
    var string: String {
        switch self {
        case .debug:
            return "debug:"
        case .info:
            return "info:"
        case .warning:
            return "warning:"
        case .error:
            return "error:"
        }
    }

    var terminalColor: String {
        switch self {
        case .debug:
            return "38m" //blue
        case .info:
            return "35m" //green
        case .warning:
            return "178m" //yellow
        case .error:
            return "197m" //red
        }
    }

    var coloredString: String {
        let reset = "\u{001b}[0m"
        let escape = "\u{001b}[38;5;"
        return escape + terminalColor + string + reset
    }
}

public protocol LoggerProtocol: AnyObject {
    func log_debug(_ message: @autoclosure () -> Any)
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
    public var level: LogLevel = .debug

    public func log_debug(_ message: @autoclosure () -> Any) {
        log(.debug, message: message())
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
        var result = ""
        if let prefix {
            result += "[\(prefix)] "
        }
        if colors {
            result += level.coloredString
        } else {
            result += level.string
        }
        result += " "
        result += "\(message())"
        print(result)
    }
}

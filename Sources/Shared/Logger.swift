//
//  Logger.swift
//  Logger
//
//  Created by Sergey Khliustin on 02.02.2023.
//

import Foundation
import Logger

func log_debug(file: StaticString = #file, function: StaticString = #function, line: Int = #line, _ message: @autoclosure () -> Any) {
    logger.log_debug(file: file, function: function, line: line, message())
}

func log_info(_ message: @autoclosure () -> Any) {
    logger.log_info(message())
}

func log_warning(_ message: @autoclosure () -> Any) {
    logger.log_warning(message())
}

func log_error(_ message: @autoclosure () -> Any) {
    logger.log_error(message())
}

var logger: LoggerProtocol {
    if let logger = Thread.current.threadDictionary["Logger"] as? LoggerProtocol {
        return logger
    } else {
        let logger = DefaultLogger()
        Thread.current.threadDictionary["Logger"] = logger
        return logger
    }
}

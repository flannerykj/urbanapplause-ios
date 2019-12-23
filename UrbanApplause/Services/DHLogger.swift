//
//  DHLogger.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-10.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

class DHLogger {
    static let timeZone = "EST"
    static var minLogLevel: Int = 0
    static var minBusgnagLevel: Int = 3

    static let formatter = DateFormatter()
    
    public enum Level: Int {
        case verbose = 0
        case debug = 1
        case info = 2
        case warning = 3
        case error = 4
    }
    
    open class func setup() {
        #if DEBUG
            
        #else
            // Bugsnag.start(withApiKey: Config.bugsnagAPIKey)
        #endif
    }
    /// log something generally unimportant (lowest priority)
    open class func verbose(_ message: @autoclosure () -> Any,
                            _ file: String = #file,
                            _ function: String = #function,
                            line: Int = #line,
                            context: Any? = nil) {
        #if swift(>=5)
        custom(level: .verbose, message: message(), file: file, function: function, line: line, context: context)
        #else
        custom(level: .verbose, message: message, file: file, function: function, line: line, context: context)
        #endif
    }

    /// log something which help during debugging (low priority)
    open class func debug(_ message: @autoclosure () -> Any,
                          _ file: String = #file,
                          _ function: String = #function,
                          line: Int = #line,
                          context: Any? = nil) {
        #if swift(>=5)
        custom(level: .debug, message: message(), file: file, function: function, line: line, context: context)
        #else
        custom(level: .debug, message: message, file: file, function: function, line: line, context: context)
        #endif
    }

    /// log something which you are really interested but which is not an issue or error (normal priority)
    open class func info(_ message: @autoclosure () -> Any,
                         _ file: String = #file,
                         _ function: String = #function,
                         line: Int = #line,
                         context: Any? = nil) {
        #if swift(>=5)
        custom(level: .info, message: message(), file: file, function: function, line: line, context: context)
        #else
        custom(level: .info, message: message, file: file, function: function, line: line, context: context)
        #endif
    }

    /// log something which may cause big trouble soon (high priority)
    open class func warning(_ message: @autoclosure () -> Any,
                            _ file: String = #file,
                            _ function: String = #function,
                            line: Int = #line,
                            context: Any? = nil) {
        #if swift(>=5)
        custom(level: .warning, message: message(), file: file, function: function, line: line, context: context)
        #else
        custom(level: .warning, message: message, file: file, function: function, line: line, context: context)
        #endif
    }

    /// log something which will keep you awake at night (highest priority)
    open class func error(_ message: @autoclosure () -> Any,
                          _ file: String = #file,
                          _ function: String = #function,
                          line: Int = #line,
                          context: Any? = nil) {
        #if swift(>=5)
        custom(level: .error, message: message(), file: file, function: function, line: line, context: context)
        #else
        custom(level: .error, message: message, file: file, function: function, line: line, context: context)
        #endif
    }

    /// custom logging to manually adjust values, should just be used by other frameworks
    public class func custom(level: Level, message: @autoclosure () -> Any,
                             file: String = #file,
                             function: String = #function,
                             line: Int = #line,
                             context: Any? = nil) {
        #if swift(>=5)
        dispatch_send(level: level, message: message(),
                      file: file, function: function, line: line, context: context)
        #else
        dispatch_send(level: level, message: message,
                      file: file, function: function, line: line, context: context)
        #endif
    }

    // Logs to console if DEBUG, sends to Bugsnag if not (granted meets min logging requirement).
    class func dispatch_send(level: Level,
                             message: @autoclosure () -> Any,
                             file: String,
                             function: String,
                             line: Int,
                             context: Any?) {
        
        var resolvedMessage: String = ""
        #if swift(>=5)
        resolvedMessage = "\(message())"
        #else
        // resolvedMessage = "\(message)"
        #endif
        let functionText: String = String(function.split(separator: "(").first ?? "")
        
        // #if DEBUG
            // Log to console
            guard level.rawValue >= minLogLevel else {
                return
            }
          
            let filename = (file.components(separatedBy: "/").last ?? file).replacingOccurrences(of: ".swift", with: "")
            
            print(
                // formattedDateString,
                level.symbol,
                level.name.uppercased(),
                filename,
                "\(functionText):\(line)",
                "--", resolvedMessage)
        /* #else
            // RELEASE: Send to Bugsnag
            if level.rawValue >= minBusgnagLevel {
                var message: String?
                var error: Error?
                
                if let error = message as? Error {
                    // Bugsnag.notifyError(_error)
                } else {
                    let exception = NSException(name: NSExceptionName(rawValue: "NamedException"),
                                                reason: resolvedMessage, userInfo: nil)
                    
                   //  Bugsnag.notify(exception)
                }
            }
         #endif */
        
    }
    class var formattedDateString: String {
        if !timeZone.isEmpty {
            formatter.timeZone = TimeZone(abbreviation: timeZone)
        }
        formatter.dateFormat = "HH:mm:ss"
        let dateStr = formatter.string(from: Date())
        return dateStr
    }
    
}

extension DHLogger.Level {
    var symbol: String {
        switch self {
        case .verbose:
            return "💜"
        case .debug:
            return "💚"
        case .info:
            return "💙"
        case .warning:
            return "💛"
        case .error:
            return "❤️"
        }
    }
    
    var name: String {
        switch self {
        case .verbose: return "verbose"
        case .debug: return "debug"
        case .info: return "info"
        case .warning: return "warning"
        case .error: return "error"
        }
    }
}

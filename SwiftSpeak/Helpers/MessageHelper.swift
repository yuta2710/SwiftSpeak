//
//  Logger.swift
//  SwiftSpeak
//
//  Created by Nguyen Phuc Loi on 05/10/2024.
//

import Foundation

enum Message {
    enum LogLevel {
        case info
        case warning
        case error
        
        fileprivate var prefix: String {
            switch self {
            case .info: return "INFO ✅"
            case .warning: return "WARNING ⚠️"
            case .error: return "ALERT ❌"
            }
        }
    }
     
    struct Context {
        let file: String
        let function: String
        let line: Int
        var description: String {
            return "\((file as NSString).lastPathComponent):\(line) \(function)"
        }
    }
    
    static func buildLogInfo(
        _ str: String,
        shouldLogContext: Bool = true,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let context = Context(file: file, function: function, line: line)
        Message.handleMessage(level: .info, str: str.description, shouldLogContext: shouldLogContext, context: context)
    }
    
    static func buildLogWarning(
        _ str: StaticString,
        shouldLogContext: Bool = true,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let context = Context(file: file, function: function, line: line)
        Message.handleMessage(level: .warning, str: str.description, shouldLogContext: shouldLogContext, context: context)
    }
    
    static func buildLogError(
        _ str: String,
        shouldLogContext: Bool = true,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let context = Context(file: file, function: function, line: line)
        Message.handleMessage(level: .error, str: str.description, shouldLogContext: shouldLogContext, context: context)
    }
    
    fileprivate static func handleMessage(level: LogLevel, str: String, shouldLogContext: Bool, context: Context) {
        let logComponents = ["[\(level.prefix)]", str]
        var fullString = logComponents.joined(separator: " ")
        
        if shouldLogContext {
            fullString += " -> \(context.description)"
        }
        
        #if DEBUG
        print(fullString)
        #endif
    }
}

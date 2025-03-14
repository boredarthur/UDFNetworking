//
//  Logging.swift
//  
//
//  Created by Arthur Zavolovych on 05.03.2025.
//

import Foundation

/// Logger for API requests and responses.
public enum APILogger {
    /// Log levels for controlling the verbosity of API logging.
    public enum LogLevel {
        /// No logging is performed.
        case none
        
        /// Only error responses and failed requests are logged.
        /// This is useful for production environments to track only problematic requests.
        case error
        
        /// Basic request and response information is logged, including URLs and status codes.
        /// This is suitable for development and testing environments.
        case debug
        
        /// Detailed logging including headers and response bodies.
        /// This provides maximum visibility but may impact performance and should only
        /// be used during development or troubleshooting.
        case verbose
    }
    
    /// The current log level.
    internal static var logLevel: LogLevel = .error
    
    /// Set the logging level. This should only be called from the API configuration.
    /// - Parameter level: The log level to set.
    internal static func setLogLevel(_ level: LogLevel) {
        logLevel = level
    }
    
    /// Log a request.
    /// - Parameter request: The URL request to log.
    public static func logRequest(_ request: URLRequest) {
        guard logLevel != .none else { return }
        
        #if DEBUG
        print("📤 REQUEST: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        
        if logLevel == .verbose {
            if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
                print("📤 HEADERS: \(headers)")
            }
            
            if let body = request.httpBody {
                if let json = JSONCoding.prettyPrint(body) {
                    print("📤 BODY: \(json)")
                } else if let bodyString = String(data: body, encoding: .utf8) {
                    print("📤 BODY: \(bodyString)")
                }
            }
        }
        #endif
    }
    
    /// Log a response.
    /// - Parameters:
    ///   - data: The response data.
    ///   - response: The URL response.
    ///   - error: An error that occurred, if any.
    ///   - url: The URL of the request.
    public static func logResponse(data: Data?, response: URLResponse?, error: Error?, url: URL?) {
        guard logLevel != .none else { return }
        
        #if DEBUG
        if let error = error {
            print("❌ ERROR: \(error.localizedDescription)")
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❓ UNKNOWN RESPONSE: \(url?.absoluteString ?? "")")
            return
        }
        
        let statusCode = httpResponse.statusCode
        let statusIcon = (200...299).contains(statusCode) ? "✅" : "❌"
        
        print("\(statusIcon) RESPONSE [\(statusCode)]: \(url?.absoluteString ?? "")")
        
        if logLevel == .verbose || (logLevel == .error && statusCode >= 400) {
            if let headers = httpResponse.allHeaderFields as? [String: Any], !headers.isEmpty {
                print("📥 HEADERS: \(headers)")
            }
            
            if let data = data, !data.isEmpty {
                if let json = JSONCoding.prettyPrint(data) {
                    print("📥 BODY: \(json)")
                } else if let bodyString = String(data: data, encoding: .utf8) {
                    print("📥 BODY: \(bodyString)")
                }
            }
        }
        #endif
    }
    
    /// Format a date for logging.
    /// - Parameter date: The date to format.
    /// - Returns: A formatted date string.
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}

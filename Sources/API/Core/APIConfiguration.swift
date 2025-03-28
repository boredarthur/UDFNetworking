//
//  APIConfiguration.swift
//  
//
//  Created by Arthur Zavolovych on 05.03.2025.
//

import Foundation

/// A protocol that defines the configuration for API clients.
public protocol APIConfigurationProtocol {
    /// Base URL for the API server.
    var baseURL: URL { get }
    
    /// Base URL for the CDN (optional).
    var cdnURL: URL? { get }
    
    /// Base URL for the media CDN (optional).
    var mediaCDNURL: URL? { get }
    
    /// Timeout interval for network requests.
    var timeoutInterval: TimeInterval { get }
    
    /// Default headers to include in every request.
    var defaultHeaders: [String: String] { get }
    
    /// Logging level for API requests and responses.
    var logLevel: APILogger.LogLevel { get }
    
    /// The name of the page parameter for pagination.
    var pageParameterName: String { get }
    
    /// The name of the per page parameter for pagination.
    var perPageParameterName: String { get }
    
    /// Get a custom value from the configuration.
    /// - Parameter key: The key for the stored value.
    /// - Returns: The stored value, or nil if not found.
    func getValue<T>(forKey key: String) -> T?
    
    /// Set a custom value in the configuration.
    /// - Parameters:
    ///   - value: The value to store.
    ///   - key: The key for the stored value.
    func setValue<T>(_ value: T, forKey key: String)
}

/// Default implementation of the APIConfigurationProtocol.
public class APIConfiguration: APIConfigurationProtocol {
    /// Base URL for the API server.
    public var baseURL: URL
    
    /// Base URL for the CDN (optional).
    public var cdnURL: URL?
    
    /// Base URL for the media CDN (optional).
    public var mediaCDNURL: URL?
    
    /// Timeout interval for network requests.
    public var timeoutInterval: TimeInterval
    
    /// Default headers to include in every request.
    public var defaultHeaders: [String: String]
    
    /// Logging level for API requests and responses.
    public var logLevel: APILogger.LogLevel
    
    /// The name of the page parameter for pagination.
    public var pageParameterName: String
    
    /// The name of the per page parameter for pagination.
    public var perPageParameterName: String
    
    /// Dictionary to store custom configuration values.
    private var customProperties: [String: Any] = [:]
    
    /// Initialize a new APIConfiguration.
    /// - Parameters:
    ///   - baseURL:Base URL for the API server. If nil, a fatal error will be triggered.
    ///   - cdnURL: Base URL for the CDN (optional).
    ///   - mediaCDNURL: Base URL for the media CDN (optional).
    ///   - timeoutInterval: Timeout interval for network requests.
    ///   - defaultHeaders: Default headers to include in every request.
    ///   - logLevel: Logging level for API requests and responses.
    public init(
        baseURL: URL?,
        cdnURL: URL? = nil,
        mediaCDNURL: URL? = nil,
        timeoutInterval: TimeInterval = 30,
        defaultHeaders: [String: String] = ["Content-Type": "application/json"],
        logLevel: APILogger.LogLevel = .error,
        pageParameterName: String = URLParameter.page.rawValue,
        perPageParameterName: String = URLParameter.perPage.rawValue
    ) {
        guard let baseURL = baseURL else {
            fatalError("baseURL cannot be nil when initializing APIConfiguration")
        }
        
        self.baseURL = baseURL
        self.cdnURL = cdnURL
        self.mediaCDNURL = mediaCDNURL
        self.timeoutInterval = timeoutInterval
        self.defaultHeaders = defaultHeaders
        self.logLevel = logLevel
        self.pageParameterName = pageParameterName
        self.perPageParameterName = perPageParameterName
    }
    
    /// Get a custom value from the configuration.
    /// - Parameter key: The key for the stored value.
    /// - Returns: The stored value, or nil if not found.
    public func getValue<T>(forKey key: String) -> T? {
        return customProperties[key] as? T
    }
    
    /// Set a custom value in the configuration.
    /// - Parameters:
    ///   - value: The value to store.
    ///   - key: The key for the stored value.
    public func setValue<T>(_ value: T, forKey key: String) {
        customProperties[key] = value
    }
}

// Extension with convenience methods for common configuration patterns
public extension APIConfiguration {
    /// Add authorization configuration.
    /// - Parameters:
    ///   - token: The type of token (e.g., "Bearer").
    ///   - defaultToken: A default token to use (optional).
    /// - Returns: Self for chaining.
    func withAuthorization(token: String, defaultToken: String? = nil) -> Self {
        setValue(token, forKey: "token")
        if let token = defaultToken {
            setValue(token, forKey: "defaultToken")
        }
        return self
    }
}

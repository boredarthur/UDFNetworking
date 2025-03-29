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
    func getValue<T>(forKey key: ConfigurationKey) -> T?
    
    /// Set a custom value in the configuration.
    /// - Parameters:
    ///   - value: The value to store.
    ///   - key: The key for the stored value.
    func setValue<T>(_ value: T, forKey key: ConfigurationKey)
    
    /// Get a custom value from the configuration using a string key.
    /// - Parameter key: The string key for the stored value.
    /// - Returns: The stored value, or nil if not found.
    func getValue<T>(forKey key: String) -> T?
    
    /// Set a custom value in the configuration using a string key.
    /// - Parameters:
    ///   - value: The value to store.
    ///   - key: The string key for the stored value.
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
    
    /// Dictionary to store custom configuration values.
    private var customProperties: [ConfigurationKey: Any] = [:]
    
    /// The name of the page parameter for pagination.
    /// Reads from customProperties, with a fallback to URLParameter.page.rawValue.
    public var pageParameterName: String {
        get { return getValue(forKey: .pageParameterName) ?? URLParameter.page.rawValue }
        set { setValue(newValue, forKey: .pageParameterName) }
    }
    
    /// The name of the per page parameter for pagination.
    /// Reads from customProperties, with a fallback to URLParameter.perPage.rawValue.
    public var perPageParameterName: String {
        get { return getValue(forKey: .perPageParameterName) ?? URLParameter.perPage.rawValue }
        set { setValue(newValue, forKey: .perPageParameterName) }
    }
    
    /// Initialize a new APIConfiguration.
    /// - Parameters:
    ///   - baseURL:Base URL for the API server. If nil, a fatal error will be triggered.
    ///   - cdnURL: Base URL for the CDN (optional).
    ///   - mediaCDNURL: Base URL for the media CDN (optional).
    ///   - timeoutInterval: Timeout interval for network requests.
    ///   - defaultHeaders: Default headers to include in every request.
    ///   - logLevel: Logging level for API requests and responses.
    ///   - customProperties: Dictionary of custom configuration properties. Keys defined in ConfigurationKey enum can be used for standard properties.
    public init(
        baseURL: URL?,
        cdnURL: URL? = nil,
        mediaCDNURL: URL? = nil,
        timeoutInterval: TimeInterval = 30,
        defaultHeaders: [String: String] = ["Content-Type": "application/json"],
        logLevel: APILogger.LogLevel = .error,
        customProperties: [ConfigurationKey: Any] = [:]
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
        
        var allProperties = customProperties
        if allProperties[.pageParameterName] == nil {
            allProperties[.pageParameterName] = URLParameter.page.rawValue
        }
        if allProperties[.perPageParameterName] == nil {
            allProperties[.perPageParameterName] = URLParameter.perPage.rawValue
        }
        
        self.customProperties = allProperties
    }
    
    /// Get a custom value from the configuration.
    /// - Parameter key: The key for the stored value.
    /// - Returns: The stored value, or nil if not found.
    public func getValue<T>(forKey key: ConfigurationKey) -> T? {
        return customProperties[key] as? T
    }
    
    /// Set a custom value in the configuration.
    /// - Parameters:
    ///   - value: The value to store.
    ///   - key: The key for the stored value.
    public func setValue<T>(_ value: T, forKey key: ConfigurationKey) {
        customProperties[key] = value
    }
    
    /// Get a custom value from the configuration using a string key (backward compatibility).
    /// - Parameter key: The string key for the stored value.
    /// - Returns: The stored value, or nil if not found.
    public func getValue<T>(forKey key: String) -> T? {
        return getValue(forKey: ConfigurationKey(rawValue: key))
    }
    
    /// Set a custom value in the configuration using a string key (backward compatibility).
    /// - Parameters:
    ///   - value: The value to store.
    ///   - key: The string key for the stored value.
    public func setValue<T>(_ value: T, forKey key: String) {
        setValue(value, forKey: ConfigurationKey(rawValue: key))
    }
    
    /// Get a custom value from the API configuration.
    /// - Parameter key: The key for the stored value.
    /// - Returns: The stored value, or nil if not found.
    static func getCustomValue<T>(forKey key: ConfigurationKey) -> T? {
        return API.configuration?.getValue(forKey: key)
    }
    
    /// Get a custom string value from the API configuration.
    /// - Parameter key: The key for the stored value.
    /// - Returns: The stored string value, or nil if not found.
    static func getCustomString(forKey key: ConfigurationKey) -> String? {
        return getCustomValue(forKey: key)
    }
    
    /// Get a custom URL value from the API configuration.
    /// This method first attempts to get a string value and then converts it to a URL.
    /// - Parameter key: The key for the stored value.
    /// - Returns: The stored URL value, or nil if not found or if the string is not a valid URL.
    static func getCustomURL(forKey key: ConfigurationKey) -> URL? {
        if let urlString: String = getCustomValue(forKey: key) {
            return URL(string: urlString)
        }
        return nil
    }
    
    /// Get a custom integer value from the API configuration.
    /// - Parameter key: The key for the stored value.
    /// - Returns: The stored integer value, or nil if not found.
    static func getCustomInt(forKey key: ConfigurationKey) -> Int? {
        return getCustomValue(forKey: key)
    }
    
    /// Get a custom double value from the API configuration.
    /// - Parameter key: The key for the stored value.
    /// - Returns: The stored double value, or nil if not found.
    static func getCustomDouble(forKey key: ConfigurationKey) -> Double? {
        return getCustomValue(forKey: key)
    }
    
    /// Get a custom boolean value from the API configuration.
    /// - Parameter key: The key for the stored value.
    /// - Returns: The stored boolean value, or nil if not found.
    static func getCustomBool(forKey key: ConfigurationKey) -> Bool? {
        return getCustomValue(forKey: key)
    }
    
    // Backward compatibility methods with string keys
    
    /// Get a custom value from the API configuration using a string key.
    /// - Parameter key: The string key for the stored value.
    /// - Returns: The stored value, or nil if not found.
    static func getCustomValue<T>(forKey key: String) -> T? {
        return getCustomValue(forKey: ConfigurationKey(rawValue: key))
    }
    
    /// Get a custom string value from the API configuration using a string key.
    /// - Parameter key: The string key for the stored value.
    /// - Returns: The stored string value, or nil if not found.
    static func getCustomString(forKey key: String) -> String? {
        return getCustomString(forKey: ConfigurationKey(rawValue: key))
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
        setValue(token, forKey: .token)
        if let token = defaultToken {
            setValue(token, forKey: .defaultToken)
        }
        return self
    }
}

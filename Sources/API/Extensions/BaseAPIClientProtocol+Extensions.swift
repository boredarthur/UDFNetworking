//
//  BaseAPIClientProtocol+Extensions.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 29.03.2025.
//

import Foundation

/// Extension to BaseAPIClientProtocol to provide easy access to custom configuration values.
public extension BaseAPIClientProtocol {
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
    
    // String-based methods for backward compatibility
    
    /// Get a custom string value from the API configuration using a string key.
    /// - Parameter key: The string key for the stored value.
    /// - Returns: The stored string value, or nil if not found.
    static func getCustomString(forKey key: String) -> String? {
        return getCustomValue(forKey: key)
    }
    
    /// Get a custom URL value from the API configuration using a string key.
    /// - Parameter key: The string key for the stored value.
    /// - Returns: The stored URL value, or nil if not found or if the string is not a valid URL.
    static func getCustomURL(forKey key: String) -> URL? {
        if let urlString: String = getCustomValue(forKey: key) {
            return URL(string: urlString)
        }
        return nil
    }
    
    /// Get a custom integer value from the API configuration using a string key.
    /// - Parameter key: The string key for the stored value.
    /// - Returns: The stored integer value, or nil if not found.
    static func getCustomInt(forKey key: String) -> Int? {
        return getCustomValue(forKey: key)
    }
    
    /// Get a custom double value from the API configuration using a string key.
    /// - Parameter key: The string key for the stored value.
    /// - Returns: The stored double value, or nil if not found.
    static func getCustomDouble(forKey key: String) -> Double? {
        return getCustomValue(forKey: key)
    }
    
    /// Get a custom boolean value from the API configuration using a string key.
    /// - Parameter key: The string key for the stored value.
    /// - Returns: The stored boolean value, or nil if not found.
    static func getCustomBool(forKey key: String) -> Bool? {
        return getCustomValue(forKey: key)
    }
}

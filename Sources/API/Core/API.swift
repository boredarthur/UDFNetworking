//
//  API.swift
//  
//
//  Created by Arthur Zavolovych on 05.03.2025.
//

import Foundation

/// Global namespace for API-related functions and properties.
public enum API {
    /// The global API configuration.
    public static var configuration: APIConfigurationProtocol!
    
    /// Configure the API with the provided configuration.
    /// - Parameter configuration: The API configuration to use.
    public static func configure(with configuration: APIConfigurationProtocol) {
        self.configuration = configuration
        // Update logger level when configuration changes
        APILogger.setLogLevel(configuration.logLevel)
    }
    
    /// Check if the API has been configured.
    /// - Returns: True if the API has been configured, false otherwise.
    public static func isConfigured() -> Bool {
        return configuration != nil
    }
    
    /// Reset the API configuration.
    public static func reset() {
        configuration = nil
        // Reset logger to default level
        APILogger.setLogLevel(.error)
    }
    
    /// Update the logging level. This is provided as a convenience method
    /// when you need to change logging without reconfiguring the entire API.
    /// - Parameter level: The new logging level.
    public static func setLoggingLevel(_ level: APILogger.LogLevel) {
        guard let configuration = configuration else {
            return
        }
        
        // This is a bit of a hack since the configuration might be immutable,
        // but we need to ensure the configuration and logger stay in sync
        if let mutableConfig = configuration as? APIConfiguration {
            mutableConfig.logLevel = level
        }
        
        APILogger.setLogLevel(level)
    }
}

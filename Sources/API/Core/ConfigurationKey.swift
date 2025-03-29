//
//  ConfigurationKey.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 29.03.2025.
//

import Foundation

/// Namespace for configuration keys used across the application.
/// This enum serves as a centralized place to define and organize configuration keys.
/// It can be extended outside the package to add application-specific keys.
public enum ConfigurationKey: Hashable {
    /// Key for the pagination parameter name. Default value is URLParameter.page.rawValue.
    case pageParameterName
    
    /// Key for the perPage parameter name. Default value is URLParameter.perPage.rawValue.
    case perPageParameterName
    
    /// Key for the authorization token
    case token
    
    /// Fallback key for the authorization token
    case defaultToken
    
    // Custom case for external extensions
    case custom(String)
    
    // Access the raw string value
    public var rawValue: String {
        switch self {
        case .pageParameterName: return "pageParameterName"
        case .perPageParameterName: return "perPageParameterName"
        case .token: return "token"
        case .defaultToken: return "defaultToken"
        case .custom(let key): return key
        }
    }
    
    // Create from string (for backward compatibility)
    public init(rawValue: String) {
        switch rawValue {
        case "pageParameterName": self = .pageParameterName
        case "perPageParameterName": self = .perPageParameterName
        case "token": self = .token
        case "defaultToken": self = .defaultToken
        default: self = .custom(rawValue)
        }
    }
}

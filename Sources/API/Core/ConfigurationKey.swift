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
public enum ConfigurationKey: String, Hashable {
    /// Key for the pagination parameter name. Default value is URLParameter.page.rawValue.
    case pageParameterName
    
    /// Key for the perPage parameter name. Default value is URLParameter.perPage.rawValue.
    case perPageParameterName
    
    /// Key for the authorization token
    case token
    
    /// Fallback key for the authorization token
    case defaultToken
}

//
//  URLParameter.swift
//  
//
//  Created by Arthur Zavolovych on 05.03.2025.
//

import Foundation

/// Standard URL parameters for API requests.
public enum URLParameter: Hashable {
    // Pagination parameters
    case page
    case perPage
    
    // Sorting and filtering
    case sortBy
    case sortOrder
    case filter
    case query
    case search
    
    // Authentication and session
    case email
    case password
    case token
    case refreshToken
    case apiKey
    case currentDatetime
    
    // User-related parameters
    case firstName
    case lastName
    case userName
    case displayName
    case profileImage
    case dateOfBirth
    case gender
    case phoneNumber
    
    // Location parameters
    case latitude
    case longitude
    case radius
    
    // Miscellaneous
    case language
    case version
    case platform
    case deviceId
    case timezone
    case format
    case id
    
    // Custom parameters
    case custom(String)
    
    /// The raw string value of the parameter.
    public var rawValue: String {
        switch self {
        // Pagination parameters
        case .page: return "page"
        case .perPage: return "per_page"
            
        // Sorting and filtering
        case .sortBy: return "sort_by"
        case .sortOrder: return "sort_order"
        case .filter: return "filter"
        case .query: return "query"
        case .search: return "search"
            
        // Authentication and session
        case .email: return "email"
        case .password: return "password"
        case .token: return "token"
        case .refreshToken: return "refresh_token"
        case .apiKey: return "api_key"
        case .currentDatetime: return "current_datetime"
            
        // User-related parameters
        case .firstName: return "first_name"
        case .lastName: return "last_name"
        case .userName: return "user_name"
        case .displayName: return "display_name"
        case .profileImage: return "profile_image"
        case .dateOfBirth: return "date_of_birth"
        case .gender: return "gender"
        case .phoneNumber: return "phone_number"
            
        // Location parameters
        case .latitude: return "lat"
        case .longitude: return "lon"
        case .radius: return "radius"
            
        // Miscellaneous
        case .language: return "language"
        case .version: return "version"
        case .platform: return "platform"
        case .deviceId: return "device_id"
        case .timezone: return "timezone"
        case .format: return "format"
        case .id: return "id"
            
        // Custom parameters
        case .custom(let param): return param
        }
    }
}

// Extension for creating URL query items
public extension URLParameter {
    /// Create a URL query item with this parameter and a value.
    /// - Parameter value: The value for the parameter.
    /// - Returns: A URLQueryItem.
    func queryItem(_ value: String?) -> URLQueryItem {
        return URLQueryItem(name: self.rawValue, value: value)
    }
    
    /// Create a URL query item with this parameter and a boolean value.
    /// - Parameter value: The boolean value.
    /// - Returns: A URLQueryItem with "true" or "false" as the value.
    func queryItem(_ value: Bool) -> URLQueryItem {
        return URLQueryItem(name: self.rawValue, value: value ? "true" : "false")
    }
    
    /// Create a URL query item with this parameter and an integer value.
    /// - Parameter value: The integer value.
    /// - Returns: A URLQueryItem with the string representation of the integer.
    func queryItem(_ value: Int) -> URLQueryItem {
        return URLQueryItem(name: self.rawValue, value: String(value))
    }
    
    /// Create a URL query item with this parameter and a double value.
    /// - Parameter value: The double value.
    /// - Returns: A URLQueryItem with the string representation of the double.
    func queryItem(_ value: Double) -> URLQueryItem {
        return URLQueryItem(name: self.rawValue, value: String(value))
    }
}

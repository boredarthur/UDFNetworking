//
//  URLParameter.swift
//  
//
//  Created by Arthur Zavolovych on 05.03.2025.
//

import Foundation

/// Standard URL parameters for API requests.
public enum URLParameter: String {
    // Pagination parameters
    case _page
    case _perPage = "per_page"
    
    // Sorting and filtering
    case sortBy = "sort_by"
    case sortOrder = "sort_order"
    case filter
    case query
    case search
    
    // Authentication and session
    case email
    case password
    case token
    case refreshToken = "refresh_token"
    case apiKey = "api_key"
    case currentDatetime = "current_datetime"
    
    // User-related parameters
    case firstName = "first_name"
    case lastName = "last_name"
    case userName = "user_name"
    case displayName = "display_name"
    case profileImage = "profile_image"
    case dateOfBirth = "date_of_birth"
    case gender
    case phoneNumber = "phone_number"
    
    // Location parameters
    case latitude = "lat"
    case longitude = "lon"
    case radius
    
    // Miscellaneous
    case language
    case version
    case platform
    case deviceId = "device_id"
    case timezone
    case format
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

// Extension for pagination
public extension URLParameter {
    /// Create a page query item with the configuration's page parameter name.
    /// - Parameter value: The page number.
    /// - Returns: A URLQueryItem for the page parameter.
    static func page(_ value: Int) -> URLQueryItem {
        let paramName = API.configuration?.pageParameterName ?? URLParameter._page.rawValue
        return URLQueryItem(name: paramName, value: String(value))
    }
    
    /// Create a per page query item with the configuration's per page parameter name.
    /// - Parameter value: The number of items per page.
    /// - Returns: A URLQueryItem for the per page parameter.
    static func perPage(_ value: Int) -> URLQueryItem {
        let paramName = API.configuration?.perPageParameterName ?? URLParameter._perPage.rawValue
        return URLQueryItem(name: paramName, value: String(value))
    }
}

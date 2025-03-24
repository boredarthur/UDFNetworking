//
//  URLComponents+Extensions.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 24.03.2025.
//

import Foundation

public extension URLComponents {
    /// Create URL components for an API endpoint with optional query parameters
    /// - Parameters:
    ///   - endpoint: The API endpoint
    ///   - queryItems: The query items to add to the URL
    /// - Returns: Configured URLComponents instance
    static func forAPI(
        endpoint: APIEndpoint,
        @URLRequest.URLQueryItemBuilder queryItems: () -> [URLQueryItem] = { [] }
    ) throws -> URLComponents {
        guard let configuration = API.configuration else {
            throw APIError.notConfigured
        }
        
        guard let string = (configuration.baseURL.absoluteString + endpoint.rawValue)
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              var components = URLComponents(string: string)
        else {
            throw APIError.invalidURL
        }
        
        let items = queryItems()
        if !items.isEmpty {
            components.queryItems = items
        }
        
        return components
    }
    
    /// Add query items to the components
    /// - Parameter items: The query items to add
    /// - Returns: Self for chaining
    @discardableResult
    mutating func addQueryItems(_ items: [URLQueryItem]) -> Self {
        if queryItems == nil {
            queryItems = items
        } else {
            queryItems?.append(contentsOf: items)
        }
        return self
    }
    
    /// Add query items to the components using a builder
    /// - Parameter builder: The query items builder
    /// - Returns: Self for chaining
    @discardableResult
    mutating func addQueryItems(@URLRequest.URLQueryItemBuilder builder: () -> [URLQueryItem]) -> Self {
        return addQueryItems(builder())
    }
}

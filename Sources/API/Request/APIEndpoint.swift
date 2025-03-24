//
//  APIEndpoint.swift
//  
//
//  Created by Arthur Zavolovych on 05.03.2025.
//

import Foundation

/// Protocol for types that can be converted to an API endpoint path.
public protocol APIEndpoint {
    /// The raw endpoint path.
    var rawValue: String { get }
}

/// Make String conform to APIEndpoint so strings can be used directly as endpoints.
extension String: APIEndpoint {
    public var rawValue: String { return self }
}

extension RawRepresentable where RawValue == String, Self: APIEndpoint {
    /// Get the endpoint path
    public var endpointPath: String { return self.rawValue }
}

/// Utility functions for working with endpoints.
public extension APIEndpoint {
    /// Replace path parameters in the endpoint with actual values.
    /// - Parameter parameters: Dictionary of parameter names and values.
    /// - Returns: The endpoint with parameters replaced.
    func substitutingParameters(_ parameters: [String: String]) -> String {
        var path = rawValue
        for (key, value) in parameters {
            path = path.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return path
    }
    
    /// Create a URL for this endpoint using the base URL.
    /// - Parameters:
    ///   - baseURL: The base URL to use.
    ///   - parameters: Path parameters to substitute.
    /// - Returns: A URL if successful, or nil if the URL couldn't be created.
    func url(with baseURL: URL, parameters: [String: String] = [:]) -> URL? {
        let path = substitutingParameters(parameters)
        return URL(string: path, relativeTo: baseURL)
    }
    
    /// Create a full path for this endpoint using the base URL.
    /// - Parameters:
    ///   - baseURL: The base URL to use.
    ///   - apiPath: Optional API path to insert between base URL and endpoint (e.g., "/api").
    /// - Returns: The full path string.
    func fullPath(with baseURL: URL, apiPath: String = "/api") -> String {
        return baseURL.absoluteString + apiPath + rawValue
    }
}

public extension APIEndpoint {
    /// Create a custom endpoint from a URL path
    /// - Parameter path: The URL path string
    /// - Returns: An APIEndpoint
    static func custom(urlPath: String) -> APIEndpoint {
        return urlPath
    }
    
    /// Create URLComponents for this endpoint
    /// - Parameter queryItems: Optional query items to include
    /// - Returns: URLComponents for the endpoint
    func components(@URLRequest.URLQueryItemBuilder queryItems: () -> [URLQueryItem] = { [] }) throws -> URLComponents {
        return try URLComponents.forAPI(endpoint: self, queryItems: queryItems)
    }
}

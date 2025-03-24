//
//  URLRequest+Extensions.swift
//  
//
//  Created by Arthur Zavolovych on 05.03.2025.
//

import Foundation

public extension URLRequest {
    /// Create a request for an API endpoint.
    /// - Parameters:
    ///   - endpoint: The API endpoint.
    ///   - httpMethod: The HTTP method.
    ///   - cachePolicy: The cache policy.
    ///   - timeoutInterval: The timeout interval.
    ///   - queryItems: The query items.
    /// - Returns: The URL request.
    static func request(
        for endpoint: APIEndpoint,
        httpMethod: HTTPMethod = .get,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        timeoutInterval: TimeInterval = 30,
        @URLQueryItemBuilder queryItems: () -> [URLQueryItem] = { [] }
    ) throws -> URLRequest {
        guard let configuration = API.configuration else {
            throw APIError.notConfigured
        }
        
        guard let string = (configuration.baseURL.absoluteString + endpoint.rawValue).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              var components = URLComponents(string: string)
        else {
            throw APIError.invalidURL
        }
        
        let items = queryItems()
        var data: Data? = nil
        
        if !items.isEmpty, httpMethod == .get {
            components.queryItems = items
        } else if !items.isEmpty, httpMethod != .get {
            var parameters: [String: Any] = [:]
            items.forEach { parameters[$0.name] = $0.value }
            data = try? JSONSerialization.data(withJSONObject: parameters)
        }
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        request.httpBody = data
        request.httpMethod = httpMethod.rawValue
        
        // Add default headers from configuration
        for (key, value) in configuration.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add current datetime header if needed
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss+0000"
        request.setValue(dateFormatter.string(from: Date()), forHTTPHeaderField: URLParameter.currentDatetime.rawValue.lowercased())
        
        return request
    }
    
    /// Set a JSON body.
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - encoder: The JSON encoder to use.
    /// - Throws: An error if encoding fails.
    mutating func setJSONBody<T: Encodable>(_ value: T, encoder: JSONEncoder = JSONEncoder()) throws {
        do {
            let jsonData = try encoder.encode(value)
            self.httpBody = jsonData
            
            // Make sure the content type is set to JSON
            if self.value(forHTTPHeaderField: "Content-Type") == nil {
                self.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        } catch {
            throw APIError.invalidBody
        }
    }
    
    /// Add an authorization header.
    /// - Parameter token: The authorization token.
    /// - Returns: The request with the authorization header.
    mutating func addAuthorization(_ token: String) -> URLRequest {
        self.setValue(token, forHTTPHeaderField: HTTPHeaderField.authorization.rawValue)
        return self
    }
    
    /// Result builder for URL query items.
    @resultBuilder
    struct URLQueryItemBuilder {
        public static func buildBlock(_ components: URLQueryItem...) -> [URLQueryItem] {
            components
        }
        
        public static func buildBlock(_ components: [URLQueryItem]...) -> [URLQueryItem] {
            components.flatMap { $0 }
        }
        
        public static func buildExpression(_ component: URLQueryItem) -> [URLQueryItem] {
            [component]
        }
        
        public static func buildExpression(_ components: [URLQueryItem]) -> [URLQueryItem] {
            components
        }
        
        public static func buildOptional(_ component: [URLQueryItem]?) -> [URLQueryItem] {
            component ?? []
        }
        
        public static func buildEither(first component: [URLQueryItem]) -> [URLQueryItem] {
            component
        }
        
        public static func buildEither(second component: [URLQueryItem]) -> [URLQueryItem] {
            component
        }
    }
}

// Extension for pagination
public extension URLQueryItem {
    /// Create a page query item with the configuration's page parameter name.
    /// - Parameter value: The page number.
    /// - Returns: A URLQueryItem for the page parameter.
    static func page(_ value: Int) -> URLQueryItem {
        let paramName = API.configuration?.pageParameterName ?? URLParameter.page.rawValue
        return URLQueryItem(name: paramName, value: String(value))
    }
    
    /// Create a per page query item with the configuration's per page parameter name.
    /// - Parameter value: The number of items per page.
    /// - Returns: A URLQueryItem for the per page parameter.
    static func perPage(_ value: Int) -> URLQueryItem {
        let paramName = API.configuration?.perPageParameterName ?? URLParameter.perPage.rawValue
        return URLQueryItem(name: paramName, value: String(value))
    }
}

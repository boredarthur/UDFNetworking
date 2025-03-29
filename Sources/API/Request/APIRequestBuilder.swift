//
//  APIRequestBuilder.swift
//  
//
//  Created by Arthur Zavolovych on 05.03.2025.
//

import Foundation

/// A helper struct for header items.
public struct HeaderItem {
    /// The header field.
    let field: HTTPHeaderField
    
    /// The header value.
    let value: String?
    
    /// Initialize a header item.
    /// - Parameters:
    ///   - field: The header field.
    ///   - value: The header value.
    public init(_ field: HTTPHeaderField, _ value: String?) {
        self.field = field
        self.value = value
    }
}

/// A builder for creating API requests.
public class APIRequest {
    /// A container for the built URL request.
    public struct RequestContainer {
        /// The URL request.
        public let urlRequest: URLRequest
        
        /// URLSession to use for the request.
        public let session: URLSession
        
        /// Initialize a request container with a URL request and session.
        /// 
        /// - Parameters:
        ///   - urlRequest: The constructed URL request.
        ///   - session: The URLSession to use for the request. Defaults to shared session.
        public init(urlRequest: URLRequest, session: URLSession = .shared) {
            self.urlRequest = urlRequest
            
            if session === URLSession.shared {
                let configuration = URLSessionConfiguration.ephemeral
                configuration.httpShouldUsePipelining = false
                configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
                configuration.timeoutIntervalForRequest = session.configuration.timeoutIntervalForRequest
                configuration.timeoutIntervalForResource = session.configuration.timeoutIntervalForResource
                
                self.session = URLSession(configuration: configuration)
            } else {
                self.session = session
            }
        }
    }
    
    /// Builder for creating API requests.
    public struct Builder {
        /// The endpoint path.
        private let endpoint: String
        
        /// The HTTP method.
        private var method: HTTPMethod = .get
        
        /// The request headers.
        private var headers: [HTTPHeaderField: String] = [:]
        
        /// The query items.
        private var queryItems: [URLQueryItem] = []
        
        /// The body parameters for non-GET requests.
        private var bodyParameters: [String: Any] = [:]
        
        /// The cache policy.
        private var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
        
        /// The timeout interval.
        private var timeoutInterval: TimeInterval?
        
        /// Custom data for the body.
        private var customBody: Data?
        
        /// Initialize a builder with an endpoint.
        /// - Parameter endpoint: The API endpoint.
        public init(endpoint: APIEndpoint) {
            self.endpoint = endpoint.rawValue
        }
        
        /// Initialize a builder with URLComponents
        /// - Parameter components: The URLComponents to use for the request
        public init(components: URLComponents) throws {
            guard let url = components.url else {
                throw APIError.invalidURL
            }
            
            // Extract the path from the URL
            // If using a base URL, we need to remove it from the path
            if let configuration = API.configuration {
                let baseURLString = configuration.baseURL.absoluteString
                let urlString = url.absoluteString
                
                if urlString.hasPrefix(baseURLString) {
                    // If URL starts with baseURL, extract just the endpoint part
                    let endpoint = String(urlString.dropFirst(baseURLString.count))
                    self.init(endpoint: endpoint)
                } else {
                    // Otherwise, use the full URL as a custom endpoint
                    self.init(endpoint: urlString as APIEndpoint)
                }
            } else {
                // If API isn't configured, use the full URL
                self.init(endpoint: url.absoluteString as APIEndpoint)
            }
            
            // If components have query items, add them as parameters
            if let queryItems = components.queryItems, !queryItems.isEmpty {
                // Use the parameters method to add query items
                _ = self.parameters {
                    queryItems
                }
            }
        }
        
        /// Set the HTTP method.
        /// - Parameter method: The HTTP method.
        /// - Returns: The updated builder.
        public func method(_ method: HTTPMethod) -> Builder {
            var builder = self
            builder.method = method
            return builder
        }
        
        /// Set the cache policy.
        /// - Parameter policy: The cache policy.
        /// - Returns: The updated builder.
        public func cachePolicy(_ policy: URLRequest.CachePolicy) -> Builder {
            var builder = self
            builder.cachePolicy = policy
            return builder
        }
        
        /// Set the timeout interval.
        /// - Parameter interval: The timeout interval.
        /// - Returns: The updated builder.
        public func timeoutInterval(_ interval: TimeInterval) -> Builder {
            var builder = self
            builder.timeoutInterval = interval
            return builder
        }
        
        /// Adds a JSON body to the request, handling different input types intelligently.
        ///
        /// This method can accept different types of inputs:
        /// - Encodable objects (will be encoded to JSON)
        /// - Data objects (if already JSON-serialized data)
        /// - Dictionaries and arrays (will be serialized to JSON)
        ///
        /// - Parameters:
        ///   - object: The object to use as the request body. Can be an `Encodable` object, pre-serialized JSON `Data`, 
        ///             a dictionary `[String: Any]`, or an array `[Any]`.
        ///   - encoder: The JSON encoder to use for encoding `Encodable` objects. Defaults to a standard encoder.
        ///
        /// - Returns: A new builder instance with the JSON body and appropriate Content-Type header added.
        ///
        /// - Note: If the provided data is already serialized JSON, it will be used directly without re-encoding.
        ///         If the object cannot be converted to valid JSON, the original builder will be returned unchanged.
        public func jsonBody<T>(_ object: T, encoder: JSONEncoder = JSONEncoder()) -> Builder {
            var newBuilder = self
            
            do {
                let jsonData: Data
                
                if let dataObject = object as? Data {
                    jsonData = dataObject
                } else if let encodableObject = object as? Encodable {
                    jsonData = try encoder.encode(encodableObject)
                } else {
                    if let dictionary = object as? [String: Any] {
                        jsonData = try JSONSerialization.data(withJSONObject: dictionary)
                    } else if let array = object as? [Any] {
                        jsonData = try JSONSerialization.data(withJSONObject: array)
                    } else {
                        return self
                    }
                }
                
                newBuilder.customBody = jsonData
                
                var updatedHeaders = newBuilder.headers
                updatedHeaders[.contentType] = "application/json"
                newBuilder.headers = updatedHeaders
                
                return newBuilder
            } catch {
                return self
            }
        }
        
        // MARK: - Header Builders
        
        /// Result builder for headers.
        @resultBuilder
        public struct HeadersBuilder {
            /// Build a block of header items.
            /// - Parameter components: The header items.
            /// - Returns: A dictionary of header fields and values.
            public static func buildBlock(_ components: HeaderItem...) -> [HTTPHeaderField: String] {
                var headers: [HTTPHeaderField: String] = [:]
                for item in components {
                    if let value = item.value {
                        headers[item.field] = value
                    }
                }
                return headers
            }
            
            /// Build an optional header item.
            /// - Parameter component: The optional header item.
            /// - Returns: The header item or nil.
            public static func buildOptional(_ component: HeaderItem?) -> HeaderItem? {
                return component
            }
            
            /// Build a conditional header item (if true).
            /// - Parameter component: The header item.
            /// - Returns: The header item.
            public static func buildEither(first component: HeaderItem) -> HeaderItem {
                return component
            }
            
            /// Build a conditional header item (if false).
            /// - Parameter component: The header item.
            /// - Returns: The header item.
            public static func buildEither(second component: HeaderItem) -> HeaderItem {
                return component
            }
            
            /// Build a block that returns an array of Header items
            /// - Parameter components: The header items.
            /// - Returns: A dictionary of header fields and values.
            public static func buildBlock(_ components: [HeaderItem]) -> [HTTPHeaderField: String] {
                var headers: [HTTPHeaderField: String] = [:]
                for item in components {
                    if let value = item.value {
                        headers[item.field] = value
                    }
                }
                return headers
            }
            
            /// Build an expression from an array of header items
            /// - Parameter expression: An array of header items
            /// - Returns: The array of header items
            public static func buildExpression(_ expression: [HeaderItem]) -> [HeaderItem] {
                return expression
            }
            
            /// Build an expression from a single header item
            /// - Parameter expression: A single header item
            /// - Returns: Array containing the header item
            public static func buildExpression(_ expression: HeaderItem) -> [HeaderItem] {
                return [expression]
            }
            
            /// Build a block with multiple arrays of header items
            /// - Parameter components: Arrays of header items
            /// - Returns: A dictionary of header fields and values
            public static func buildBlock(_ components: [HeaderItem]...) -> [HTTPHeaderField: String] {
                var headers: [HTTPHeaderField: String] = [:]
                for component in components {
                    for item in component {
                        if let value = item.value {
                            headers[item.field] = value
                        }
                    }
                }
                return headers
            }
        }
        
        /// Set headers using a result builder.
        /// - Parameter builder: The header builder.
        /// - Returns: The updated builder.
        public func headers(@HeadersBuilder builder: () -> [HTTPHeaderField: String]) -> Builder {
            var newBuilder = self
            
            let newHeaders = builder()
            
            var mergedHeaders = newBuilder.headers
            for (key, value) in newHeaders {
                mergedHeaders[key] = value
            }
            
            newBuilder.headers = mergedHeaders
            return newBuilder
        }
        
        // MARK: - Parameter Builders
        
        /// Result builder for URL query parameters.
        @resultBuilder
        public struct ParametersBuilder {
            /// Builds a block of URL query items.
            /// - Parameter components: The individual URL query items.
            /// - Returns: An array of URL query items.
            public static func buildBlock(_ components: URLQueryItem...) -> [URLQueryItem] {
                return components
            }
            
            /// Builds an empty block of URL query items.
            /// - Returns: An empty array of URL query items.
            public static func buildBlock() -> [URLQueryItem] {
                return []
            }
            
            /// Builds an optional block of URL query items.
            /// Used when an if-statement without an else clause is encountered.
            /// - Parameter component: The optional array of URL query items.
            /// - Returns: The array of URL query items if present, otherwise an empty array.
            public static func buildOptional(_ component: [URLQueryItem]?) -> [URLQueryItem] {
                return component ?? []
            }
            
            /// Builds the first (true) branch of an if-else statement with a single URL query item.
            /// - Parameter component: The URL query item from the true branch.
            /// - Returns: An array containing the URL query item.
            public static func buildEither(first component: URLQueryItem) -> [URLQueryItem] {
                return [component]
            }
            
            /// Builds the second (false) branch of an if-else statement with a single URL query item.
            /// - Parameter component: The URL query item from the false branch.
            /// - Returns: An array containing the URL query item.
            public static func buildEither(second component: URLQueryItem) -> [URLQueryItem] {
                return [component]
            }
            
            /// Builds the first (true) branch of an if-else statement with multiple URL query items.
            /// - Parameter component: The array of URL query items from the true branch.
            /// - Returns: The array of URL query items.
            public static func buildEither(first component: [URLQueryItem]) -> [URLQueryItem] {
                return component
            }
            
            /// Builds the second (false) branch of an if-else statement with multiple URL query items.
            /// - Parameter component: The array of URL query items from the false branch.
            /// - Returns: The array of URL query items.
            public static func buildEither(second component: [URLQueryItem]) -> [URLQueryItem] {
                return component
            }
            
            /// Converts a single URL query item to an array.
            /// - Parameter expression: A single URL query item.
            /// - Returns: An array containing the URL query item.
            public static func buildExpression(_ expression: URLQueryItem) -> [URLQueryItem] {
                return [expression]
            }
            
            /// Passes through an array of URL query items.
            /// - Parameter expression: An array of URL query items.
            /// - Returns: The same array of URL query items.
            public static func buildExpression(_ expression: [URLQueryItem]) -> [URLQueryItem] {
                return expression
            }
            
            /// Combines multiple arrays of URL query items.
            /// - Parameter components: The arrays of URL query items to combine.
            /// - Returns: A single flattened array of URL query items.
            public static func buildBlock(_ components: [URLQueryItem]...) -> [URLQueryItem] {
                return components.flatMap { $0 }
            }
        }
        
        /// Set parameters using a result builder.
        /// - Parameter builder: The parameter builder.
        /// - Returns: The updated builder.
        public func parameters(@ParametersBuilder builder parameters: () -> [URLQueryItem]) -> Builder {
            var newBuilder = self
            
            // For GET requests, these are query parameters
            if method == .get || method == .delete {
                newBuilder.queryItems = parameters()
                return newBuilder
            }
            
            // For other methods (POST, PUT, PATCH), convert to body
            var bodyDict: [String: Any] = [:]
            
            for item in parameters() {
                // Try to convert query items to body parameters
                if let value = item.value {
                    // Convert string to appropriate type if possible
                    if let intValue = Int(value) {
                        bodyDict[item.name] = intValue
                    } else if let doubleValue = Double(value) {
                        bodyDict[item.name] = doubleValue
                    } else if let boolValue = Bool(value) {
                        bodyDict[item.name] = boolValue
                    } else {
                        bodyDict[item.name] = value
                    }
                }
            }
            
            // Store body parameters for processing in build method
            newBuilder.bodyParameters = bodyDict
            
            return newBuilder
        }
        
        // MARK: - Convenience Methods
        
        /// Add authentication to the request.
        /// - Parameter token: The authentication token.
        /// - Returns: The updated builder.
        public func authenticated(with token: String?) -> Builder {
            guard let token = token, !token.isEmpty else { return self }
            
            var newBuilder = self
            
            var updatedHeaders = newBuilder.headers
            updatedHeaders[.authorization] = token
            newBuilder.headers = updatedHeaders
            
            return newBuilder
        }
        
        /// Add pagination parameters to the request.
        /// - Parameters:
        ///   - page: The page number.
        ///   - perPage: The number of items per page.
        /// - Returns: The updated builder.
        public func paged(page: Int, perPage: Int = 20) -> Builder {
            return parameters {
                let config = API.configuration
                let pageParam = config?.pageParameterName ?? URLParameter.page.rawValue
                let perPageParam = config?.perPageParameterName ?? URLParameter.perPage.rawValue
                
                URLQueryItem(name: pageParam, value: "\(page)")
                URLQueryItem(name: perPageParam, value: "\(perPage)")
            }
        }
        
        // MARK: - Build Method
        
        /// Build the request.
        /// - Parameter session: The URLSession to use for making requests.
        /// - Returns: The request container.
        public func build(session: URLSession = .shared) throws -> RequestContainer {
            guard let configuration = API.configuration else {
                throw APIError.notConfigured
            }
            
            return try build(with: configuration)
        }
        
        /// Build the request with a specific configuration.
        /// - Parameters:
        ///   - configuration: The API configuration to use.
        ///   - session: The URLSession to use for making requests.
        /// - Returns: The request container.
        /// - Throws: APIError.invalidURL if the URL cannot be constructed.
        public func build(
            with configuration: APIConfigurationProtocol,
            session: URLSession = .shared
        ) throws -> RequestContainer {
            guard let string = (configuration.baseURL.absoluteString + endpoint).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  var components = URLComponents(string: string)
            else {
                throw APIError.invalidURL
            }
            
            if !queryItems.isEmpty && method == .get {
                components.queryItems = queryItems
            }
            
            guard let url = components.url else {
                throw APIError.invalidURL
            }
            
            var request = URLRequest(
                url: url, 
                cachePolicy: cachePolicy,
                timeoutInterval: timeoutInterval ?? configuration.timeoutInterval
            )
            request.httpMethod = method.rawValue
            
            // Add default headers from configuration
            for (key, value) in configuration.defaultHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            // Add custom headers
            for (field, value) in headers {
                request.setValue(value, forHTTPHeaderField: field.rawValue)
            }
            
            // Handle body for non-GET requests
            if let customBody {
                request.httpBody = customBody
            } else if method != .get {
                // Process bodyParameters for non-GET requests
                if !bodyParameters.isEmpty {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: bodyParameters)
                        request.httpBody = jsonData
                        
                        // Ensure content-type is set to application/json
                        if request.value(forHTTPHeaderField: "Content-Type") == nil {
                            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        }
                    } catch {
                        throw APIError.invalidBody
                    }
                }
            }
            
            return RequestContainer(urlRequest: request, session: session)
        }
        
        /// Build a request directly from URLComponents
        /// - Parameters:
        ///   - components: The URLComponents to use
        ///   - session: The URLSession to use for making requests
        /// - Returns: The request container
        /// - Throws: An error if the build fails
        public func build(_ components: URLComponents, session: URLSession = .shared) throws -> RequestContainer {
            guard let url = components.url else {
                throw APIError.invalidURL
            }
            
            var request = URLRequest(
                url: url,
                cachePolicy: cachePolicy,
                timeoutInterval: timeoutInterval ?? API.configuration?.timeoutInterval ?? 30
            )
            request.httpMethod = method.rawValue
            
            if let defaultHeaders = API.configuration?.defaultHeaders {
                for (key, value) in defaultHeaders {
                    request.setValue(value, forHTTPHeaderField: key)
                }
            }
            
            // Add custom headers
            for (field, value) in headers {
                request.setValue(value, forHTTPHeaderField: field.rawValue)
            }
            
            // Handle body for non-GET requests
            if let customBody {
                request.httpBody = customBody
            } else if method != .get && !bodyParameters.isEmpty {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: bodyParameters)
                    request.httpBody = jsonData
                    
                    // Ensure content-type is set to application/json
                    if request.value(forHTTPHeaderField: "Content-Type") == nil {
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    }
                } catch {
                    throw APIError.invalidBody
                }
            }
            
            return RequestContainer(urlRequest: request, session: session)
        }
    }
}

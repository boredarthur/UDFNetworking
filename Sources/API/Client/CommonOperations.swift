//
//  CommonOperations.swift
//  
//
//  Created by Arthur Zavolovych on 05.03.2025.
//

import Foundation

/// Extension with common API operations.
public extension BaseAPIClientProtocol {
    // MARK: - Resource Operations
    
    /// Fetch a resource.
    /// - Parameters:
    ///   - endpoint: The API endpoint.
    ///   - token: The authentication token (if any).
    ///   - resourceKey: The key to unwrap the response by (if any).
    ///   - session: URLSession to use for the request (defaults to shared).
    ///   - parameters: The query parameters for GET requests.
    /// - Returns: The decoded resource.
    /// - Throws: An error if the request fails.
    static func fetchResource<T: Decodable>(
        endpoint: APIEndpoint,
        token: String? = nil,
        unwrapBy resourceKey: String? = nil,
        session: URLSession = .shared,
        @APIRequest.Builder.ParametersBuilder parameters: () -> [URLQueryItem] = { [] }
    ) async throws -> T {
        let request = try APIRequest.Builder(endpoint: endpoint)
            .method(.get)
            .authenticated(with: token)
            .parameters(builder: parameters)
            .build()
        
        return try await performRequest(with: request.urlRequest, unwrapBy: resourceKey)
    }
    
    /// Fetch a resource using custom URLComponents
    /// - Parameters:
    ///   - components: The URLComponents to use
    ///   - token: The authentication token (if any)
    ///   - resourceKey: The key to unwrap the response by (if any)
    ///   - session: URLSession to use for the request (defaults to shared)
    /// - Returns: The decoded resource
    /// - Throws: An error if the request fails
    static func fetchResource<T: Decodable>(
        _ components: URLComponents,
        token: String? = nil,
        unwrapBy resourceKey: String? = nil,
        session: URLSession = .shared
    ) async throws -> T {
        let request = try APIRequest.Builder(components: components)
            .method(.get)
            .authenticated(with: token)
            .build(components, session: session)
        
        return try await performRequest(with: request.urlRequest, unwrapBy: resourceKey, session: session)
    }
    
    /// Fetch a collection of resources.
    /// - Parameters:
    ///   - endpoint: The API endpoint.
    ///   - token: The authentication token (if any).
    ///   - collectionKey: The key to unwrap the collection by (if any).
    ///   - session: URLSession to use for the request (defaults to shared).
    ///   - parameters: The query parameters for GET requests.
    /// - Returns: The decoded collection.
    /// - Throws: An error if the request fails.
    static func fetchCollection<T: Decodable>(
        endpoint: APIEndpoint,
        token: String? = nil,
        unwrapBy collectionKey: String? = nil,
        session: URLSession = .shared,
        @APIRequest.Builder.ParametersBuilder parameters: () -> [URLQueryItem] = { [] }
    ) async throws -> [T] {
        let request = try APIRequest.Builder(endpoint: endpoint)
            .method(.get)
            .authenticated(with: token)
            .parameters(builder: parameters)
            .build()
        
        return try await performRequest(with: request.urlRequest, unwrapBy: collectionKey)
    }
    
    /// Fetch a collection of resources using custom URLComponents
    /// - Parameters:
    ///   - components: The URLComponents to use
    ///   - token: The authentication token (if any)
    ///   - collectionKey: The key to unwrap the collection by
    ///   - session: URLSession to use for the request (defaults to shared)
    /// - Returns: The decoded collection
    /// - Throws: An error if the request fails
    static func fetchCollection<T: Decodable>(
        components: URLComponents,
        token: String? = nil,
        unwrapBy collectionKey: String? = nil,
        session: URLSession = .shared
    ) async throws -> [T] {
        let request = try APIRequest.Builder(components: components)
            .method(.get)
            .authenticated(with: token)
            .build(components, session: session)
        
        return try await performRequest(with: request.urlRequest, unwrapBy: collectionKey, session: session)
    }
    
    /// Fetch a paginated collection of resources.
    /// - Parameters:
    ///   - endpoint: The API endpoint.
    ///   - page: The page number.
    ///   - perPage: The number of items per page.
    ///   - token: The authentication token (if any).
    ///   - collectionKey: The key to unwrap the collection by.
    ///   - session: URLSession to use for the request (defaults to shared).
    ///   - additionalParameters: Additional query parameters for the request.
    /// - Returns: The decoded collection.
    /// - Throws: An error if the request fails.
    static func fetchCollection<T: Decodable>(
        endpoint: APIEndpoint,
        page: Int,
        perPage: Int = 20,
        token: String? = nil,
        unwrapBy collectionKey: String? = nil,
        session: URLSession = .shared,
        @APIRequest.Builder.ParametersBuilder additionalParameters: () -> [URLQueryItem] = { [] }
    ) async throws -> [T] {
        guard let configuration = API.configuration else {
            throw APIError.notConfigured
        }
        
        let request = try APIRequest.Builder(endpoint: endpoint)
            .method(.get)
            .authenticated(with: token)
            .parameters {
                URLQueryItem(name: configuration.pageParameterName, value: "\(page)")
                URLQueryItem(name: configuration.perPageParameterName, value: "\(perPage)")
                
                additionalParameters()
            }
            .build(session: session)
        
        return try await performRequest(with: request.urlRequest, unwrapBy: collectionKey, session: session)
    }
    
    /// Fetch a paginated collection of resources using URLComponents.
    /// - Parameters:
    ///   - components: Base URLComponents to use.
    ///   - page: The page number.
    ///   - perPage: The number of items per page.
    ///   - token: The authentication token (if any).
    ///   - collectionKey: The key to unwrap the collection by.
    ///   - session: URLSession to use for the request (defaults to shared).
    ///   - additionalParameters: Additional query parameters for the request.
    /// - Returns: The decoded collection.
    /// - Throws: An error if the request fails.
    static func fetchCollection<T: Decodable>(
        _ components: URLComponents,
        page: Int,
        perPage: Int = 20,
        token: String? = nil,
        unwrapBy collectionKey: String? = nil,
        session: URLSession = .shared,
        @APIRequest.Builder.ParametersBuilder additionalParameters: () -> [URLQueryItem] = { [] }
    ) async throws -> [T] {
        guard let configuration = API.configuration else {
            throw APIError.notConfigured
        }
        
        var paginatedComponents = components
        paginatedComponents.addQueryItems {
            URLQueryItem(name: configuration.pageParameterName, value: "\(page)")
            URLQueryItem(name: configuration.perPageParameterName, value: "\(perPage)")
            
            // Add any additional parameters
            additionalParameters()
        }
        
        let request = try APIRequest.Builder(components: paginatedComponents)
            .method(.get)
            .authenticated(with: token)
            .build(paginatedComponents, session: session)
        
        return try await performRequest(with: request.urlRequest, unwrapBy: collectionKey, session: session)
    }
    
    // MARK: - Write Operations
    
    /// Create a resource.
    /// - Parameters:
    ///   - endpoint: The API endpoint.
    ///   - token: The authentication token (if any).
    ///   - resourceKey: The key to unwrap the response by (if any).
    ///   - session: URLSession to use for the request (defaults to shared).
    ///   - parameters: The parameters for the request body in POST requests.
    /// - Returns: The created resource.
    /// - Throws: An error if the request fails.
    static func createResource<T: Decodable>(
        endpoint: APIEndpoint,
        token: String? = nil,
        unwrapBy resourceKey: String? = nil,
        session: URLSession = .shared,
        @APIRequest.Builder.ParametersBuilder parameters: () -> [URLQueryItem] = { [] }
    ) async throws -> T {
        let request = try APIRequest.Builder(endpoint: endpoint)
            .method(.post)
            .authenticated(with: token)
            .parameters(builder: parameters)
            .build()
        
        return try await performRequest(with: request.urlRequest, unwrapBy: resourceKey)
    }
    
    /// Create a resource using URLComponents
    /// - Parameters:
    ///   - components: The URLComponents to use
    ///   - token: The authentication token (if any)
    ///   - resourceKey: The key to unwrap the response by (if any)
    ///   - bodyParameters: The body parameters builder
    ///   - session: URLSession to use for the request
    /// - Returns: The created resource
    /// - Throws: An error if the request fails
    static func createResource<T: Decodable>(
        _ components: URLComponents,
        token: String? = nil,
        unwrapBy resourceKey: String? = nil,
        @APIRequest.Builder.ParametersBuilder bodyParameters: () -> [URLQueryItem] = { [] },
        session: URLSession = .shared
    ) async throws -> T {
        let request = try APIRequest.Builder(components: components)
            .method(.post)
            .authenticated(with: token)
            .parameters(builder: bodyParameters)
            .build(components, session: session)
        
        return try await performRequest(with: request.urlRequest, unwrapBy: resourceKey, session: session)
    }
    
    /// Update a resource.
    /// - Parameters:
    ///   - endpoint: The API endpoint.
    ///   - token: The authentication token (if any).
    ///   - resourceKey: The key to unwrap the response by (if any).
    ///   - session: URLSession to use for the request (defaults to shared).
    ///   - parameters: The parameters for the request body in PUT requests.
    /// - Returns: The updated resource.
    /// - Throws: An error if the request fails.
    static func updateResource<T: Decodable>(
        endpoint: APIEndpoint,
        token: String? = nil,
        unwrapBy resourceKey: String? = nil,
        session: URLSession = .shared,
        @APIRequest.Builder.ParametersBuilder parameters: () -> [URLQueryItem] = { [] }
    ) async throws -> T {
        let request = try APIRequest.Builder(endpoint: endpoint)
            .method(.put)
            .authenticated(with: token)
            .parameters(builder:parameters)
            .build()
        
        return try await performRequest(with: request.urlRequest, unwrapBy: resourceKey)
    }
    
    /// Update a resource using URLComponents
    /// - Parameters:
    ///   - components: The URLComponents to use
    ///   - token: The authentication token (if any)
    ///   - resourceKey: The key to unwrap the response by (if any)
    ///   - bodyParameters: The body parameters builder
    ///   - session: URLSession to use for the request
    /// - Returns: The updated resource
    /// - Throws: An error if the request fails
    static func updateResource<T: Decodable>(
        _ components: URLComponents,
        token: String? = nil,
        unwrapBy resourceKey: String? = nil,
        @APIRequest.Builder.ParametersBuilder bodyParameters: () -> [URLQueryItem] = { [] },
        session: URLSession = .shared
    ) async throws -> T {
        let request = try APIRequest.Builder(components: components)
            .method(.put)
            .authenticated(with: token)
            .parameters(builder: bodyParameters)
            .build(components, session: session)
        
        return try await performRequest(with: request.urlRequest, unwrapBy: resourceKey, session: session)
    }
    
    /// Patch a resource.
    /// - Parameters:
    ///   - endpoint: The API endpoint.
    ///   - token: The authentication token (if any).
    ///   - resourceKey: The key to unwrap the response by (if any).
    ///   - session: URLSession to use for the request (defaults to shared).
    ///   - parameters: The parameters for the request body in PATCH requests.
    /// - Returns: The patched resource.
    /// - Throws: An error if the request fails.
    static func patchResource<T: Decodable>(
        endpoint: APIEndpoint,
        token: String? = nil,
        unwrapBy resourceKey: String? = nil,
        session: URLSession = .shared,
        @APIRequest.Builder.ParametersBuilder parameters: () -> [URLQueryItem] = { [] }
    ) async throws -> T {
        let request = try APIRequest.Builder(endpoint: endpoint)
            .method(.patch)
            .authenticated(with: token)
            .parameters(builder:parameters)
            .build()
        
        return try await performRequest(with: request.urlRequest, unwrapBy: resourceKey)
    }
    
    /// Patch a resource using URLComponents
    /// - Parameters:
    ///   - components: The URLComponents to use
    ///   - token: The authentication token (if any)
    ///   - resourceKey: The key to unwrap the response by (if any)
    ///   - bodyParameters: The body parameters builder
    ///   - session: URLSession to use for the request
    /// - Returns: The patched resource
    /// - Throws: An error if the request fails
    static func patchResource<T: Decodable>(
        _ components: URLComponents,
        token: String? = nil,
        unwrapBy resourceKey: String? = nil,
        @APIRequest.Builder.ParametersBuilder bodyParameters: () -> [URLQueryItem] = { [] },
        session: URLSession = .shared
    ) async throws -> T {
        let request = try APIRequest.Builder(components: components)
            .method(.patch)
            .authenticated(with: token)
            .parameters(builder: bodyParameters)
            .build(components, session: session)
        
        return try await performRequest(with: request.urlRequest, unwrapBy: resourceKey, session: session)
    }
    
    /// Delete a resource.
    /// - Parameters:
    ///   - endpoint: The API endpoint.
    ///   - token: The authentication token (if any).
    ///   - session: URLSession to use for the request (defaults to shared).
    ///   - parameters: Optional parameters for DELETE requests.
    /// - Throws: An error if the request fails.
    static func deleteResource(
        endpoint: APIEndpoint,
        token: String? = nil,
        session: URLSession = .shared,
        @APIRequest.Builder.ParametersBuilder parameters: () -> [URLQueryItem] = { [] }
    ) async throws {
        let request = try APIRequest.Builder(endpoint: endpoint)
            .method(.delete)
            .authenticated(with: token)
            .parameters(builder: parameters)
            .build()
        
        try await performRequestWithNoResponse(with: request.urlRequest)
    }
    
    /// Delete a resource using URLComponents
    /// - Parameters:
    ///   - components: The URLComponents to use
    ///   - token: The authentication token (if any)
    ///   - session: URLSession to use for the request
    /// - Throws: An error if the request fails
    static func deleteResource(
        _ components: URLComponents,
        token: String? = nil,
        session: URLSession = .shared
    ) async throws {
        let request = try APIRequest.Builder(components: components)
            .method(.delete)
            .authenticated(with: token)
            .build(components, session: session)
        
        try await performRequestWithNoResponse(with: request.urlRequest, session: session)
    }
}

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
}

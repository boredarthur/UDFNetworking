//
//  BaseAPIClientProtocol.swift
//  
//
//  Created by Arthur Zavolovych on 05.03.2025.
//

import Foundation

/// Protocol for API clients.
public protocol BaseAPIClientProtocol {
    /// The endpoint type associated with this API client
    associatedtype Endpoints: APIEndpoint
    
    /// Perform a request that returns a decodable model.
    /// - Parameters:
    ///   - request: The URL request.
    ///   - key: The key to unwrap the response by (if any).
    ///   - session: URLSession to use for the request (defaults to shared).
    /// - Returns: The decoded model.
    /// - Throws: An error if the request fails.
    static func performRequest<T: Decodable>(
        with request: URLRequest,
        unwrapBy key: String?,
        session: URLSession
    ) async throws -> T
    
    /// Perform a request that does not return a response body.
    /// - Parameters:
    ///  - request: The URL request.
    ///  - session: URLSession to use for the request (defaults to shared).
    /// - Throws: An error if the request fails.
    static func performRequestWithNoResponse(
        with request: URLRequest,
        session: URLSession
    ) async throws
}

/// Default implementation of BaseAPIClientProtocol.
public extension BaseAPIClientProtocol {
    /// Perform a request that returns a decodable model.
    /// - Parameters:
    ///   - request: The URL request.
    ///   - key: The key to unwrap the response by (if any).
    ///   - session: URLSession to use for the request (defaults to shared).
    /// - Returns: The decoded model.
    /// - Throws: An error if the request fails.
    static func performRequest<T: Decodable>(
        with request: URLRequest,
        unwrapBy key: String? = nil,
        session: URLSession = .shared
    ) async throws -> T {
        // Check if the API is configured
        guard API.isConfigured() else {
            throw APIError.notConfigured
        }
        
        // Log the request if enabled
        APILogger.logRequest(request)
        
        return try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: request) { data, response, error in
                // Log the response
                APILogger.logResponse(data: data, response: response, error: error, url: request.url)
                
                if let error = error {
                    continuation.resume(throwing: APIError.networkError(error))
                    return
                }
                
                guard let data = data, let response = response else {
                    continuation.resume(throwing: APIError.invalidResponse)
                    return
                }
                
                do {
                    let validatedData = try RequestValidation.validate(data, response)
                    let result = try ResponseDecoding.decode(validatedData, as: T.self, unwrapBy: key)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }.resume()
        }
    }
    
    /// Perform a request that does not return a response body.
    /// - Parameters:
    ///   - request: The URL request.
    ///   - session: URLSession to use for the request (defaults to shared).
    /// - Throws: An error if the request fails.
    static func performRequestWithNoResponse(
        with request: URLRequest,
        session: URLSession = .shared
    ) async throws {
        // Check if the API is configured
        guard API.isConfigured() else {
            throw APIError.notConfigured
        }
        
        // Log the request if enabled
        APILogger.logRequest(request)
        
        return try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: request) { data, response, error in
                // Log the response
                APILogger.logResponse(data: data, response: response, error: error, url: request.url)
                
                if let error = error {
                    continuation.resume(throwing: APIError.networkError(error))
                    return
                }
                
                guard let data = data, let response = response else {
                    continuation.resume(throwing: APIError.invalidResponse)
                    return
                }
                
                do {
                    try RequestValidation.validate(data, response)
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }.resume()
        }
    }
}

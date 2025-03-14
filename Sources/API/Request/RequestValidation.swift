//
//  RequestValidation.swift
//  
//
//  Created by Arthur Zavolovych on 05.03.2025.
//

import Foundation

/// Utility functions for validating API responses.
public enum RequestValidation {
    /// Validate a response and return the data if successful.
    /// - Parameters:
    ///   - data: The response data.
    ///   - response: The URL response.
    /// - Returns: The validated data.
    /// - Throws: An APIError if validation fails.
    @discardableResult
    public static func validate(_ data: Data, _ response: URLResponse) throws -> Data {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let serverError = ServerError(data: data, response: httpResponse)
            throw APIError.statusCode(
                httpResponse.statusCode,
                serverError ?? CustomError("Unknown server error"),
                serverError?.meta
            )
        }
        
        return data
    }
}

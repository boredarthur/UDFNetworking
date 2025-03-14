//
//  ResponseDecoding.swift
//  
//
//  Created by Arthur Zavolovych on 05.03.2025.
//

import Foundation

/// Utility for decoding API responses.
public enum ResponseDecoding {
    /// Default JSON decoder with common settings.
    public static let defaultDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    /// Decode a data object into a model.
    /// - Parameters:
    ///   - data: The data to decode.
    ///   - type: The model type.
    ///   - decoder: The JSON decoder to use (defaults to standard configuration).
    /// - Returns: The decoded model.
    /// - Throws: An error if decoding fails.
    public static func decode<T: Decodable>(_ data: Data, as type: T.Type, decoder: JSONDecoder = defaultDecoder) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            #if DEBUG
            print("Decoding error: \(error)")
            #endif
            throw APIError.invalidJSON
        }
    }
    
    /// Decode a data object into a model, unwrapping it from a container if needed.
    /// - Parameters:
    ///   - data: The data to decode.
    ///   - type: The model type.
    ///   - key: The key to unwrap the data from (if any).
    ///   - decoder: The JSON decoder to use (defaults to standard configuration).
    /// - Returns: The decoded model.
    /// - Throws: An error if decoding fails.
    public static func decode<T: Decodable>(
        _ data: Data,
        as type: T.Type,
        unwrapBy key: String? = nil,
        decoder: JSONDecoder = defaultDecoder
    ) throws -> T {
        if let key = key, !key.isEmpty {
            // Try to unwrap the data using the key
            guard let unwrapKey = CodingUserInfoKey(rawValue: "unwrap_key") else {
                throw APIError.invalidKey
            }
            decoder.userInfo[unwrapKey] = key
            
            do {
                return try decoder.decode(UnwrapContainer<T>.self, from: data).value
            } catch {
                // Fall back to direct decoding if unwrapping fails
                #if DEBUG
                print("Unwrapping error: \(error), falling back to direct decoding")
                #endif
                return try decode(data, as: type, decoder: decoder)
            }
        } else {
            // Direct decoding
            return try decode(data, as: type, decoder: decoder)
        }
    }
}

//
//  UnwrapContainer.swift
//  
//
//  Created by Arthur Zavolovych on 05.03.2025.
//

import Foundation

/// The key used to store the unwrap key in the decoder's user info.
public let kUnwrapKey = "unwrap_key"

/// A container that unwraps nested JSON values.
public struct UnwrapContainer<Value: Decodable>: Decodable {
    /// The unwrapped value.
    public let value: Value
    
    /// A dynamic coding key for accessing properties by name.
    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        
        var intValue: Int?
        init?(intValue: Int) { nil }
    }
    
    /// Initialize from a decoder.
    /// - Parameter decoder: The decoder.
    /// - Throws: An error if decoding fails.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        let keys = container.allKeys
        
        if let codingKey = CodingUserInfoKey(rawValue: kUnwrapKey),
           let wrapKey = decoder.userInfo[codingKey] as? String,
           let decodeKey = DynamicCodingKeys(stringValue: wrapKey)
        {
        // Unwrap from the specified key
        value = try container.decode(Value.self, forKey: decodeKey)
        } else if !keys.isEmpty {
            guard let firstKey = keys.first else {
                throw APIError.missingKey
            }
            value = try container.decode(Value.self, forKey: firstKey)
        } else {
            // Try to decode the container directly as the value type
            let singleValueContainer = try decoder.singleValueContainer()
            value = try singleValueContainer.decode(Value.self)
        }
    }
}

/// Extension for KeyedDecodingContainer to handle optional decoding.
public extension KeyedDecodingContainer {
    /// Decode a value if present, or return nil if missing or fails to decode.
    /// - Parameter key: The coding key.
    /// - Returns: The decoded value or nil.
    func decodeSafely<T: Decodable>(_ key: KeyedDecodingContainer.Key) -> T? {
        return try? decode(T.self, forKey: key)
    }
    
    /// Decode a value from a key.
    /// - Parameter key: The coding key.
    /// - Returns: The decoded value.
    /// - Throws: An error if decoding fails.
    func decode<T: Decodable>(_ key: KeyedDecodingContainer.Key) throws -> T {
        return try decode(T.self, forKey: key)
    }
}

//
//  JSONCoding.swift
//  
//
//  Created by Arthur Zavolovych on 05.03.2025.
//

import Foundation

/// Utilities for JSON encoding and decoding.
public enum JSONCoding {
    /// Default JSON encoder with common settings.
    public static let defaultEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    /// Default JSON decoder with common settings.
    public static let defaultDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    /// Encode a value to JSON data.
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - encoder: The JSON encoder to use.
    /// - Returns: The encoded JSON data.
    /// - Throws: An error if encoding fails.
    public static func encode<T: Encodable>(_ value: T, encoder: JSONEncoder = defaultEncoder) throws -> Data {
        return try encoder.encode(value)
    }
    
    /// Encode a value to a JSON string.
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - encoder: The JSON encoder to use.
    /// - Returns: The encoded JSON string.
    /// - Throws: An error if encoding fails.
    public static func encodeToString<T: Encodable>(_ value: T, encoder: JSONEncoder = defaultEncoder) throws -> String {
        let data = try encode(value, encoder: encoder)
        if let string = String(data: data, encoding: .utf8) {
            return string
        }
        throw APIError.invalidJSON
    }
    
    /// Decode a JSON data to a value.
    /// - Parameters:
    ///   - data: The JSON data.
    ///   - type: The value type.
    ///   - decoder: The JSON decoder to use.
    /// - Returns: The decoded value.
    /// - Throws: An error if decoding fails.
    public static func decode<T: Decodable>(_ data: Data, as type: T.Type, decoder: JSONDecoder = defaultDecoder) throws -> T {
        return try decoder.decode(type, from: data)
    }
    
    /// Decode a JSON string to a value.
    /// - Parameters:
    ///   - string: The JSON string.
    ///   - type: The value type.
    ///   - decoder: The JSON decoder to use.
    /// - Returns: The decoded value.
    /// - Throws: An error if decoding fails.
    public static func decode<T: Decodable>(_ string: String, as type: T.Type, decoder: JSONDecoder = defaultDecoder) throws -> T {
        guard let data = string.data(using: .utf8) else {
            throw APIError.invalidJSON
        }
        return try decode(data, as: type, decoder: decoder)
    }
    
    /// Pretty print JSON data.
    /// - Parameter data: The JSON data.
    /// - Returns: A formatted JSON string.
    public static func prettyPrint(_ data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return nil
        }
        
        // First get the standard pretty-printed JSON
        guard let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return nil
        }
        
        // Now customize it to match the preferred format (unquoted keys)
        let customPrettyString = prettifyCustomFormat(prettyString)
        return customPrettyString
    }
    
    /// Helper function to customize JSON formatting to match preferred style
    private static func prettifyCustomFormat(_ jsonString: String) -> String {
        // Replace quoted keys with unquoted keys
        // This is a simple approach - a more robust solution would use a proper JSON parser
        var result = jsonString
        
        // Regular expression to match JSON keys: "key" :
        let pattern = "\"([^\"]*)\" :"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: result.utf16.count)
            
            // Replace quoted keys with unquoted
            result = regex.stringByReplacingMatches(
                in: result,
                options: [],
                range: range,
                withTemplate: "$1:"
            )
        } catch {
            // If regex fails, return the original pretty-printed string
            return jsonString
        }
        
        return result
    }
}

//
//  APIError.swift
//  
//
//  Created by Arthur Zavolovych on 05.03.2025.
//

import Foundation

/// Error types for API requests.
public enum APIError: LocalizedError {
    /// The URL is invalid.
    case invalidURL
    
    /// The request body is invalid.
    case invalidBody
    
    /// The response data is empty.
    case emptyData
    
    /// The response JSON is invalid.
    case invalidJSON
    
    /// The response is invalid.
    case invalidResponse
    
    /// The key is invalid
    case invalidKey
    
    /// The key is missing
    case missingKey
    
    /// An HTTP status code error occurred.
    /// - Parameters:
    ///   - code: The HTTP status code.
    ///   - error: The underlying error.
    ///   - meta: Additional metadata about the error.
    case statusCode(Int, Error, [String: Any]?)
    
    /// A network error occurred.
    case networkError(Error)
    
    /// The API is not configured.
    case notConfigured
    
    /// A custom error with a message.
    case custom(String)
    
    /// A description of the error.
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid."
        case .invalidBody:
            return "The request body is invalid."
        case .emptyData:
            return "The response data is empty."
        case .invalidJSON:
            return "The response JSON is invalid."
        case .invalidResponse:
            return "The response is invalid."
        case let .statusCode(_, error, _):
            return error.localizedDescription
        case let .networkError(error):
            return "Network error: \(error.localizedDescription)"
        case .notConfigured:
            return "The API is not configured. Call API.configure() before making requests."
        case .invalidKey:
            return "The included key is invalid."
        case .missingKey:
            return "Missing key"
        case let .custom(message):
            return message
        }
    }
    
    /// The HTTP status code of the error, if applicable.
    public var statusCode: Int? {
        if case let .statusCode(code, _, _) = self {
            return code
        }
        return nil
    }
    
    /// Additional metadata about the error, if available.
    public var meta: [String: Any]? {
        if case let .statusCode(_, _, meta) = self {
            return meta
        }
        return nil
    }
    
    /// The underlying error, if available.
    public var underlyingError: Error? {
        switch self {
        case let .statusCode(_, error, _):
            return error
        case let .networkError(error):
            return error
        default:
            return nil
        }
    }
}

extension APIError: Equatable {
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL):
            return true
        case (.invalidBody, .invalidBody):
            return true
        case (.emptyData, .emptyData):
            return true
        case (.invalidJSON, .invalidJSON):
            return true
        case (.invalidResponse, .invalidResponse):
            return true
        case (.notConfigured, .notConfigured):
            return true
        case let (.statusCode(lhsCode, lhsError, lhsMeta), .statusCode(rhsCode, rhsError, rhsMeta)):
            guard lhsCode == rhsCode else { return false }
            let errorsMatch = lhsError.localizedDescription == rhsError.localizedDescription
            let metaMatch = compareDictionaries(lhsMeta, rhsMeta)
            
            return errorsMatch && metaMatch
        case let (.networkError(lhsError), .networkError(rhsError)):
            return (lhsError as NSError) == (rhsError as NSError)
        case let (.custom(lhsMessage), .custom(rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
    
    private static func compareDictionaries(_ lhs: [String: Any]?, _ rhs: [String: Any]?) -> Bool {
        // If both are nil, they match
        guard let lhs = lhs, let rhs = rhs else {
            return lhs == nil && rhs == nil
        }
        
        // Check if dictionaries have same keys
        guard lhs.keys == rhs.keys else { return false }
        
        // Compare each value
        for key in lhs.keys {
            guard let lhsValue = lhs[key], let rhsValue = rhs[key] else {
                return false
            }
            
            // Basic comparison, might need to be more sophisticated for complex types
            if let lhsString = lhsValue as? String, 
                let rhsString = rhsValue as? String {
                if lhsString != rhsString { return false }
            } else if let lhsInt = lhsValue as? Int, 
                        let rhsInt = rhsValue as? Int {
                if lhsInt != rhsInt { return false }
            } else if let lhsBool = lhsValue as? Bool, 
                        let rhsBool = rhsValue as? Bool {
                if lhsBool != rhsBool { return false }
            } else {
                // If types don't match or are more complex, fall back to string representation
                if String(describing: lhsValue) != String(describing: rhsValue) {
                    return false
                }
            }
        }
        
        return true
    }
}

/// Error structure for server-returned errors.
public struct ServerError: LocalizedError {
    /// Description of the errors.
    private var errorsDescription: String
    
    /// Metadata associated with the error.
    public var meta: [String: Any]?
    
    /// Initialize a server error from response data.
    /// - Parameters:
    ///   - data: The response data.
    ///   - response: The HTTP response.
    public init?(data: Data, response: HTTPURLResponse) {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            #if DEBUG
            errorsDescription = "DEBUG\n" + "Status code: \(response.statusCode)\n" +
            "URL: \(response.url?.absoluteString ?? "NONE")\n" +
            (ErrorInfo(rawValue: response.statusCode)?.description ?? "Error")
            
            return
            #endif
            return nil
        }
        
        errorsDescription = Self.mapJsonToErrorString(json)
        self.meta = json["meta"] as? [String: Any]
        
        #if DEBUG
        errorsDescription = "DEBUG\n" + "Status code: \(response.statusCode)\n" + "URL: \(response.url?.absoluteString ?? "NONE")" +
        "\nError body:\n" + Self
            .mapJsonToErrorString(json) + "\n" + (ErrorInfo(rawValue: response.statusCode)?.description ?? "Error")
        
        #endif
    }
    
    /// Get a localized description of the error.
    public var errorDescription: String? {
        errorsDescription
    }
    
    /// Common HTTP error types.
    private enum ErrorInfo: Int {
        case unauthorized = 401
        case forbidden = 403
        case notFound = 404
        case validationErrors = 422
        case internalServer = 500
        
        var description: String {
            switch self {
            case .unauthorized:
                return "Unauthorized\nMaybe you forgot to add token to request or it isn't valid.\n Check your token"
            case .forbidden:
                return "Forbidden\nYour user with this token haven't permissions to make this action."
            case .notFound:
                return "Not found\nThere isn't info at this endpoint. Please check the correctness of the entered request or requested object"
            case .validationErrors:
                return "Validation Error\n Please check correctness of data which you send to server. If your validator is not synchronized with the server one or server don't tell us whats wrong."
            case .internalServer:
                return "Internal Server\nOoh you broke the server or it doesn't work now."
            }
        }
    }
    
    /// Maps a JSON error object to a string representation.
    /// - Parameter json: The JSON error object.
    /// - Returns: A string representation of the error.
    private static func mapJsonToErrorString(_ json: [String: Any]) -> String {
        json.compactMap { tuple in
            guard tuple.key != "meta" else { return nil }
            
            if let jsonValue = tuple.value as? [String: Any] {
                return mapJsonToErrorString(jsonValue)
                
            } else if let string = tuple.value as? String {
                return tuple.key + " - " + string
                
            } else if let array = tuple.value as? [String] {
                return tuple.key + " - " + array.joined(separator: ",")
            }
            
            return nil
        }
        .joined(separator: "\n")
    }
}

/// A simple custom error type.
public struct CustomError: LocalizedError, Error {
    /// The error message.
    public let message: String
    
    /// Initialize a custom error with a message.
    /// - Parameter message: The error message.
    public init(_ message: String) {
        self.message = message
    }
    
    /// Get a localized description of the error.
    public var errorDescription: String? {
        return message
    }
}

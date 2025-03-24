//
//  HTTPTypes.swift
//  
//
//  Created by Arthur Zavolovych on 05.03.2025.
//

import Foundation

/// HTTP methods used for API requests.
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Common HTTP header fields used in requests.
public enum HTTPHeaderField {
    case authorization
    case contentType
    case accept
    case acceptLanguage
    case acceptEncoding
    case userAgent
    case cacheControl
    case apiKey
    case apiVersion
    case apiAuthorization
    case languagePreferences
    case prefer
    case custom(String)
    
    public var rawValue: String {
        switch self {
        case .authorization: return "Authorization"
        case .contentType: return "Content-Type"
        case .accept: return "Accept"
        case .acceptLanguage: return "Accept-Language"
        case .acceptEncoding: return "Accept-Encoding"
        case .userAgent: return "User-Agent"
        case .cacheControl: return "Cache-Control"
        case .apiKey: return "Api-Key"
        case .apiVersion: return "Api-Version"
        case .apiAuthorization: return "Api-Authorization"
        case .languagePreferences: return "X-Language-Preferences"
        case .prefer: return "Prefer"
        case .custom(let name): return name
        }
    }
}

/// Common content types used in HTTP requests.
public enum ContentType: String {
    case json = "application/json"
    case formUrlEncoded = "application/x-www-form-urlencoded"
    case multipartFormData = "multipart/form-data"
    case textPlain = "text/plain"
    case xml = "application/xml"
}

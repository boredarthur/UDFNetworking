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
public enum HTTPHeaderField: String {
    case authorization = "Authorization"
    case contentType = "Content-Type"
    case accept = "Accept"
    case acceptLanguage = "Accept-Language"
    case acceptEncoding = "Accept-Encoding"
    case userAgent = "User-Agent"
    case cacheControl = "Cache-Control"
    case apiKey = "Api-Key"
    case apiVersion = "Api-Version"
    case apiAuthorization = "Api-Authorization"
    case languagePreferences = "X-Language-Preferences"
}

/// Common content types used in HTTP requests.
public enum ContentType: String {
    case json = "application/json"
    case formUrlEncoded = "application/x-www-form-urlencoded"
    case multipartFormData = "multipart/form-data"
    case textPlain = "text/plain"
    case xml = "application/xml"
}

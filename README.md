# UDFNetworking

A modern, type-safe networking layer for Swift applications built to work seamlessly with the [UDF (Unidirectional Data Flow) architecture](https://github.com/Maks-Jago/SwiftUI-UDF).

## Overview

UDFNetworking provides an elegant way to interact with REST APIs while maintaining the principles of the UDF pattern. This package offers:

- 🌐 Clean, declarative API for network requests
- 🔄 Seamless integration with UDF architecture
- 🧩 Type-safe endpoint definitions
- 🎯 Automatic request and response processing
- 📝 Extensive logging features for debugging

## Installation

### Swift Package Manager

Add UDFNetworking to your project using Swift Package Manager by adding it to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/boredarthur/UDFNetworking", from: "x.x.x")
]
```

Or add it directly in Xcode:
1. Select File > Swift Packages > Add Package Dependency
2. Enter the repository URL
3. Follow the prompts to add the package to your project

## Getting Started

For basic usage, see the quick examples below. For comprehensive examples and advanced usage, check out our [Complete Usage Guide](USAGE_GUIDE.md).

### 1. Configure the API

First, set up your API configuration:

```swift
// Initialize the configuration
let configuration = APIConfiguration(
    baseURL: URL(string: "https://api.example.com"),
    defaultHeaders: [
        HTTPHeaderField.contentType.rawValue: "application/json",
        HTTPHeaderField.prefer.rawValue: "return=representation",
        "api-key": EnvironmentConfig.value(for: .apiKey) // Or any other way to retrieve your api key
    ]
)

// Configure the API
API.configure(with: configuration)
```

### 2. Define Endpoints

Create enums that conform to `APIEndpoint` for your API endpoints:

```swift
enum UserEndpoints: APIEndpoint {
    case profile(id: Int)
    case follow(id: Int)
    case reviews(id: Int)
    
    var rawValue: String {
        switch self {
        case let .profile(id):
            return "/v1/users/\(id)"
        case let .follow(id):
            return "/v1/users/\(id)/followed_user"
        case let .reviews(id):
            return "/v1/users/\(id)/reviews"
        }
    }
}
```

### 3. Create API Clients

Create API clients that conform to `BaseAPIClientProtocol`:

```swift
enum UserAPIClient: BaseAPIClientProtocol {
    enum UserEndpoints: APIEndpoint {
        case profile(id: Int)
        case follow(id: Int)
        case reviews(id: Int)
        
        var rawValue: String {
            switch self {
            case let .profile(id):
                return "/v1/users/\(id)"
            case let .follow(id):
                return "/v1/users/\(id)/followed_user"
            case let .reviews(id):
                return "/v1/users/\(id)/reviews"
            }
        }
    }

    static func getUserProfile(id: Int, token: String) async throws -> UserModel {
        return try await fetchResource(
            endpoint: .profile(id: id),
            token: token,
            unwrapBy: "user"
            ) {
                URLQueryItem(name: URLParameter.includeFollowers.rawValue, value: "true")
            }
        )
    }
    
    static func followUser(id: Int, token: String) async throws -> UserModel {
        return try await createResource(
            endpoint: .follow(id: id),
            token: token,
            unwrapBy: "user"
        )
    }
}
```

## Documentation

- [Complete Usage Guide](USAGE_GUIDE.md) - Comprehensive examples and advanced usage
- [Logging System](LOGGING.md) - Detailed information about the logging system

## About

UDFNetworking is designed to work with the [UDF Architecture](https://github.com/Maks-Jago/SwiftUI-UDF), a Redux-inspired unidirectional data flow pattern for SwiftUI applications.

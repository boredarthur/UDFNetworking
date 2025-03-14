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
    .package(url: "https://github.com/boredarthur/UDFNetworking", from: "1.0.0")
]
```

Or add it directly in Xcode:
1. Select File > Swift Packages > Add Package Dependency
2. Enter the repository URL
3. Follow the prompts to add the package to your project

## Getting Started

### 1. Configure the API

First, set up your API configuration:

```swift
// Initialize the configuration
let configuration = APIConfiguration(
    baseURL: URL(string: "https://api.example.com")!,
    timeoutInterval: 30,
    defaultHeaders: ["Content-Type": "application/json"]
)

// Configure the API
API.configure(with: configuration)
```

### 2. Define Endpoints

Create enums that conform to `APIEndpoint` for your API endpoints:

```swift
enum UserEndpoints {
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

extension UserEndpoints: APIEndpoint {}
```

### 3. Create API Clients

Create API clients that conform to `BaseAPIClientProtocol`:

```swift
enum UserAPIClient: BaseAPIClientProtocol {
    static func getUserProfile(id: Int, token: String) async throws -> UserModel {
        return try await fetchResource(
            endpoint: UserEndpoints.profile(id: id),
            token: token,
            unwrapBy: "user",
            parameters: {
                URLQueryItem(name: URLParameter.includeFollowers.rawValue, value: "true")
            }
        )
    }
    
    static func followUser(id: Int, token: String) async throws -> UserModel {
        return try await createResource(
            endpoint: UserEndpoints.follow(id: id),
            token: token,
            unwrapBy: "user",
            parameters: {}
        )
    }
}
```

### 4. Use in UDF Architecture

Integrate with your UDF architecture by dispatching API calls from your effects:

```swift
struct UserProfileEffect: Effect {
    let userId: Int
    let token: String
    
    func perform() async throws -> Action {
        do {
            let user = try await UserAPIClient.getUserProfile(id: userId, token: token)
            return UserProfileAction.userLoaded(user)
        } catch {
            return UserProfileAction.loadingFailed(error)
        }
    }
}
```

## Advanced Usage

### Custom URL Parameters

You can extend the `URLParameter` enum to add your own parameters:

```swift
extension URLParameter {
    static let includeFollowers = URLParameter(rawValue: "include_followers")
    static let includeReviews = URLParameter(rawValue: "include_reviews")
}
```

### Custom Headers

Add custom headers to your requests:

```swift
let request = APIRequest.Builder(endpoint: endpoint)
    .method(.get)
    .headers {
        HeaderItem(.authorization, token)
        HeaderItem(.apiVersion, "2.0")
    }
    .build()
```

# UDFNetworking Logging System

UDFNetworking includes a comprehensive logging system to help with debugging and monitoring network requests. This document explains how to configure and use the logging system effectively.

## Log Levels

The logging system supports four distinct levels of verbosity:

| Level | Description |
|-------|-------------|
| `.none` | No logging is performed. Use this in production environments where logging is not needed. |
| `.error` | Only errors and failed requests are logged. This is the default setting and is suitable for most production environments. |
| `.debug` | Basic request and response information is logged, including URLs, methods, and status codes. Useful for development and testing environments. |
| `.verbose` | Detailed information including headers, request bodies, and response bodies is logged. This provides maximum visibility but may impact performance and should only be used during development or troubleshooting. |

## Configuring Logging

Logging is configured as part of your API configuration. This ensures that logging settings are centralized and consistent:

```swift
// For development environment with detailed logging
let devConfig = APIConfiguration(
    baseURL: URL(string: "https://api.example.com")!,
    timeoutInterval: 30,
    defaultHeaders: ["Content-Type": "application/json"],
    logLevel: .verbose  // Enable detailed logging
)

// For production environment with minimal logging
let prodConfig = APIConfiguration(
    baseURL: URL(string: "https://api.example.com")!,
    timeoutInterval: 30,
    defaultHeaders: ["Content-Type": "application/json"],
    logLevel: .error  // Only log errors
)

// Configure the API based on environment
API.configure(with: isDebug ? devConfig : prodConfig)
```

## Changing Log Levels Dynamically

You can change the log level after the initial configuration:

```swift
// Update log level dynamically
API.setLoggingLevel(.debug)
```

This is useful when you need to temporarily increase logging verbosity to diagnose issues.

## Example Log Output

Here's what to expect at different log levels:

### Error Level (`.error`)

Only errors are logged:

```
❌ ERROR [401]: https://api.example.com/login
📥 BODY: {"error": "Invalid credentials", "message": "The username or password is incorrect"}
```

### Debug Level (`.debug`)

Basic request and response information:

```
📤 REQUEST: POST https://api.example.com/login
✅ RESPONSE [200]: https://api.example.com/login
```

### Verbose Level (`.verbose`)

Detailed request and response information:

```
📤 REQUEST: POST https://api.example.com/login
📤 HEADERS: {
  "Content-Type": "application/json",
  "Accept": "application/json",
  "User-Agent": "MyApp/1.0"
}
📤 BODY: {
  "email": "user@example.com",
  "password": "************"
}

✅ RESPONSE [200]: https://api.example.com/login
📥 HEADERS: {
  "Content-Type": "application/json",
  "Content-Length": "357",
  "Server": "nginx/1.18.0"
}
📥 BODY: {
  "user": {
    "id": 123,
    "name": "John Doe",
    "email": "user@example.com"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

## Best Practices

1. **Production Settings**: Use `.none` or `.error` in production to minimize performance impact and avoid logging sensitive information.

2. **Development Settings**: Use `.debug` or `.verbose` during development to help diagnose issues.

3. **Sensitive Information**: Be aware that `.verbose` logging may include sensitive information like tokens or personal data. Never use this level in production.

4. **Log Filtering**: The logging system automatically masks password fields, but you should be careful with other sensitive data.

5. **Conditional Logging**: Consider setting up environment-based logging:

```swift
#if DEBUG
    API.setLoggingLevel(.verbose)
#else
    API.setLoggingLevel(.error)
#endif
```

## Customizing Logging

If you need to customize the logging format or destination, you can extend the `APILogger` with your own implementation:

```swift
extension APILogger {
    static func customLogRequest(_ request: URLRequest) {
        // Your custom logging implementation
        // This could send logs to a file, analytics service, etc.
    }
}
```

## Log Rotation and Storage

The built-in logger outputs to the console only and does not persist logs. If you need to store logs, consider implementing a custom logging solution that integrates with your application's logging infrastructure.

## License

[Specify your license here]

## About

UDFNetworking is designed to work with the [UDF Architecture](https://github.com/Maks-Jago/SwiftUI-UDF), a Redux-inspired unidirectional data flow pattern for SwiftUI applications.

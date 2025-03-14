# UDFNetworking

A powerful and flexible networking library for Swift applications that provides a clean, type-safe API for making HTTP requests.

## Features

- 🔧 Easy configuration with customizable base URLs, timeouts, and headers
- 🚀 Modern async/await API support
- 🔒 Type-safe request and response handling
- 📝 Comprehensive logging system with multiple log levels
- 🔄 Flexible request builder pattern
- 🎯 Built-in response validation and error handling
- 💾 Configurable caching policies
- 🔍 Support for multiple environments (API, CDN, Media CDN)
- 🛠 Extensible architecture

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "YOUR_REPOSITORY_URL", from: "VERSION")
]
```

## Basic Usage

### Configuration

Configure the API client before making any requests:

```swift
let configuration = APIConfiguration(
    baseURL: URL(string: "https://api.example.com")!,
    cdnURL: URL(string: "https://cdn.example.com")!, // Optional
    mediaCDNURL: URL(string: "https://media.example.com")!, // Optional
    timeoutInterval: 30,
    defaultHeaders: ["Content-Type": "application/json"],
    logLevel: .debug
)

API.configure(with: configuration)
```

### Making Requests

Create and execute requests using the builder pattern:

```swift
// Define your endpoints
enum Endpoints: String, APIEndpoint {
    case users = "/users"
    case user = "/users/{id}"
}

// Make a GET request
let request = try APIRequest.Builder(endpoint: Endpoints.users)
    .method(.get)
    .build()

// Execute the request
let users: [User] = try await BaseAPIClient.performRequest(with: request.urlRequest)

// POST request with body
let createRequest = try APIRequest.Builder(endpoint: Endpoints.users)
    .method(.post)
    .setJSONBody(newUser)
    .build()

let createdUser: User = try await BaseAPIClient.performRequest(with: createRequest.urlRequest)
```

### Error Handling

The library provides comprehensive error handling through `APIError`:

```swift
do {
    let users = try await fetchUsers()
} catch let error as APIError {
    switch error {
    case .invalidURL:
        // Handle invalid URL
    case .networkError(let underlying):
        // Handle network errors
    case .statusCode(let code, let error, let meta):
        // Handle HTTP status code errors
    // ... handle other cases
    }
}
```

### Logging

Configure logging level to control debug output:

```swift
API.setLoggingLevel(.debug) // Options: .verbose, .debug, .info, .warning, .error, .none
```

## Advanced Features

### Custom Headers

```swift
let request = try APIRequest.Builder(endpoint: Endpoints.users)
    .method(.get)
    .headers([
        .init(.authorization, "Bearer \(token)"),
        .init(.accept, "application/json")
    ])
    .build()
```

### Query Parameters

```swift
let request = try APIRequest.Builder(endpoint: Endpoints.users)
    .method(.get)
    .parameters {
        URLQueryItem(name: "page", value: "1")
        URLQueryItem(name: "per_page", value: "20")
    }
    .build()
```

### Custom Configuration Per Request

```swift
let customConfig = APIConfiguration(
    baseURL: URL(string: "https://api2.example.com")!,
    timeoutInterval: 60
)

let request = try APIRequest.Builder(endpoint: Endpoints.users)
    .method(.get)
    .build(with: customConfig)
```

### Caching

```swift
let request = try APIRequest.Builder(endpoint: Endpoints.users)
    .method(.get)
    .cachePolicy(.returnCacheDataElseLoad)
    .build()
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[Your License Here] 
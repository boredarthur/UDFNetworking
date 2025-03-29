# UDFNetworking Usage Guide

This guide demonstrates how to use the UDFNetworking library in your Swift applications.

## Table of Contents

- [Getting Started](#getting-started)
- [API Configuration](#api-configuration)
- [Defining Endpoints](#defining-endpoints)
- [Creating API Clients](#creating-api-clients)
- [Making Network Requests](#making-network-requests)
- [Working with the Response](#working-with-the-response)
- [Advanced Features](#advanced-features)
- [Error Handling](#error-handling)

## Getting Started

First, add UDFNetworking to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/boredarthur/UDFNetworking", from: "x.x.x")
]
```

Then import the package in your Swift files:

```swift
import UDFNetworking
```

## API Configuration

Before making any API requests, you need to configure the API with your server details:

```swift
// Configure API when your app launches
func setupAPI() {
    let configuration = APIConfiguration(
        baseURL: URL(string: "https://api.example.com"),
        timeoutInterval: 30,
        defaultHeaders: [
        	HTTPHeaderField.contentType.rawValue: "application/json",
        	HTTPHeaderField.prefer.rawValue: "return=representation",
        	"api-key": EnvironmentConfig.value(for: .apiKey) // Or any other way to retrieve your api key
        ]
        logLevel: .debug // Use .error in production
    )
    
    API.configure(with: configuration)
}
```

You would typically call this configuration method in your `AppDelegate.swift` or `App.swift` file.

### Logging Levels

Choose an appropriate logging level based on your environment:

```swift
// For development with detailed logs
API.setLoggingLevel(.verbose)

// For production with minimal logs
API.setLoggingLevel(.error)

// To disable logging completely
API.setLoggingLevel(.none)
```

## Defining Endpoints

Create an enum that conforms to `APIEndpoint` to define your API endpoints:

```swift
enum UserEndpoints: APIEndpoint {
    case profile(id: Int)
    case followers(userId: Int, page: Int)
    case posts(userId: Int)
    case createPost
    
    var rawValue: String {
        switch self {
        case let .profile(id):
            return "/users/\(id)"
        case let .followers(userId, page):
            return "/users/\(userId)/followers?page=\(page)"
        case let .posts(userId):
            return "/users/\(userId)/posts"
        case .createPost:
            return "/posts"
        }
    }
}
```

## Creating API Clients

Define your API client that conforms to `BaseAPIClientProtocol`:

```swift
enum UserAPIClient: BaseAPIClientProtocol {
    typealias Endpoints = UserEndpoints
    
    /// Rest of the file...
}
```

Or you can define Endpoints right in the client:


```swift
public enum UserAPIClient: BaseAPIClientProtocol {
    public enum UserEndpoints: APIEndpoint {
    	case profile(id: Int)
    	case followers(userId: Int, page: Int)
    	case posts(userId: Int)
    	case createPost
    	    
    	public var rawValue: String {
            switch self {
            case let .profile(id):
                return "/users/\(id)"
            case let .followers(userId):
                return "/users/\(userId)/followers"
            case let .posts(userId):
                return "/users/\(userId)/posts"
            case .createPost:
                return "/posts"
            }
        }
    }
    
    /// Rest of the file...
}
```

## Making Network Requests

Now implement methods for your API client to perform network requests:

### Fetching Data (GET)

```swift
public enum UserAPIClient: BaseAPIClientProtocol {
    public enum UserEndpoints: APIEndpoint {
    	case profile(id: Int)
    	case followers(userId: Int, page: Int)
    	case posts(userId: Int)
    	case createPost
    	    
    	public var rawValue: String {
            switch self {
            case let .profile(id):
                return "/users/\(id)"
            case let .followers(userId, page):
                return "/users/\(userId)/followers?page=\(page)"
            case let .posts(userId):
                return "/users/\(userId)/posts"
            case .createPost:
                return "/posts"
            }
        }
    }

    // Fetch a user profile
    public static func getUserProfile(id: Int, token: String) async throws -> User {
        return try await fetchResource(
            endpoint: .profile(id: id),
            token: token,
            unwrapBy: "user" // If response is wrapped like {"user": {...}}
        )
    }
    
    // Fetch a list of followers
    public static func getUserFollowers(userId: Int, page: Int, token: String) async throws -> UserList {
        return try await fetchResource(
            endpoint: .followers(userId: userId),
            token: token
        ) {
            URLQueryItem.page(page)
        }
    
    // Fetch a paginated collection
    public static func getUserFollowersWithPagination(userId: Int, page: Int, token: String) async throws -> [User] {
        return try await fetchCollection(
            endpoint: .followers(userId: userId),
            page: page, // Use pagination parameters instead
            perPage: 20,
            token: token,
            unwrapBy: "users"
        )
    }
}
```

### Creating Data (POST)

```swift
public extension UserAPIClient {
    // Create a new post
    public static func createPost(content: String, token: String) async throws -> Post {
        return try await createResource(
            endpoint: Endpoints.createPost,
            token: token,
            unwrapBy: "post") {
                URLQueryItem(name: URLParameter.content.rawValue, value: content)
            }
        )
    }
    
    // Create a post with JSON body
    public static func createPostWithJSON(content: String, token: String) async throws -> Post {
        // Create a model for the request body
        struct PostRequest: Encodable {
            let content: String
        }
        
        // Encode the request body
        let request = PostRequest(content: content)
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        
        // Send the request with the encoded body
        return try await createResource(
            endpoint: Endpoints.createPost,
            bodyData: data,
            token: token,
            unwrapBy: "post"
        )
    }
}
```

### Updating Data (PUT/PATCH)

```swift
public extension UserAPIClient {
    // Update a user profile with PUT
    public static func updateUserProfile(id: Int, displayName: String, bio: String?, token: String) async throws -> User {
        return try await updateResource(
            endpoint: .profile(id: id),
            token: token,
            unwrapBy: "user") {
                URLQueryItem(name: URLParameter.displayName.rawValue, value: displayName)
                
                if let bio {
                    URLQueryItem(name: URLParameter.bio.rawValue, value: bio)
                }
            }
        )
    }
    
    // Update a user profile with PATCH (partial update)
    public static func patchUserProfile(id: Int, bio: String, token: String) async throws -> User {
        return try await patchResource(
            endpoint: .profile(id: id),
            token: token,
            unwrapBy: "user",
            parameters: {
                URLQueryItem(name: URLParameter.bio.rawValue, value: bio)
            }
        )
    }
}
```

### Deleting Data (DELETE)

```swift
public extension UserAPIClient {
    // Delete a post
    public static func deletePost(postId: Int, token: String) async throws {
        try await deleteResource(
            endpoint: .post(id: postId),
            token: token
        )
    }
}
```

## Working with the Response

### Handling Decodable Models

The library automatically decodes responses to your model types:

```swift
do {
    let user = try await UserAPIClient.getUserProfile(id: 123, token: authToken)
    
    // Now you can use the user object
    print("Username: \(user.username)")
    print("Display name: \(user.displayName)")
} catch {
    print("Error: \(error)")
}
```

### Unwrapping Nested Responses

If your API returns responses wrapped in a container:

```json
{
    "user": {
        "id": 123,
        "username": "john_doe",
        "display_name": "John Doe"
    }
}
```

You can unwrap them using the `unwrapBy` parameter:

```swift
// This will automatically extract the user object from inside the "user" field
let user = try await UserAPIClient.fetchResource(
    endpoint: .profile(id: 123),
    token: authToken,
    unwrapBy: "user"
)
```

## Advanced Features

### Custom Headers

```swift
let request = try await UserAPIClient.fetchResource(
    endpoint: .profile(id: 123),
    token: authToken,
    unwrapBy: "user",
    additionalHeaders: {
        HeaderItem(.acceptLanguage, "en-US")
        HeaderItem(.userAgent, "MyApp/1.0")
        HeaderItem(.custom("X-Custom-Header"), "CustomValue")
    }
)
```

### Conditional Parameters

```swift
try await UserAPIClient.fetchCollection(
    endpoint: .posts(userId: 123),
    token: authToken,
    unwrapBy: "posts",
    parameters: {
        URLQueryItem(name: URLParameter.includeComments.rawValue, value: "true")
        
        if includeImages {
            URLQueryItem(name: URLParameter.includeImages.rawValue, value: "true")
        }
        
        if let fromDate {
            let formatter = ISO8601DateFormatter()
            URLQueryItem(name: URLParameter.fromDate.rawValue, value: formatter.string(from: fromDate))
        }
    }
)
```

### Custom URL Components

```swift
// Create custom URLComponents
var components = URLComponents()
components.scheme = "https"
components.host = "api.example.com"
components.path = "/v2/search"
components.queryItems = [
    URLQueryItem(name: "q", value: searchTerm),
    URLQueryItem(name: "type", value: "user")
]

// Use the components with the API client
let searchResults: SearchResults = try await SearchAPIClient.fetchResource(
    components,
    token: authToken,
    unwrapBy: "results"
)
```

### Custom Configuration

```swift
// Create a separate configuration for a different API
let mediaConfig = APIConfiguration(
    baseURL: URL(string: "https://media.example.com")!,
    timeoutInterval: 60,
    defaultHeaders: ["Content-Type": "application/json"]
)

// Use it for a specific request
let urlRequest = try APIRequest.Builder(endpoint: MediaEndpoints.upload)
    .method(.post)
    .jsonBody(uploadData)
    .authenticated(with: token)
    .build(with: mediaConfig)
    .urlRequest

// Execute the request
let response: UploadResponse = try await MediaAPIClient.performRequest(
    with: urlRequest
)
```

## Error Handling

### User-Friendly Error Messages

```swift
func handleAPIError(_ error: Error) -> String {
    if let apiError = error as? APIError {
        switch apiError {
        case .networkError:
            return "Please check your internet connection and try again."
            
        case let .statusCode(code, _, _):
            switch code {
            case 401:
                return "Your session has expired. Please log in again."
            case 403:
                return "You don't have permission to perform this action."
            case 404:
                return "The requested resource was not found."
            case 429:
                return "You've made too many requests. Please wait and try again."
            case 500...599:
                return "There was an issue with our servers. Please try again later."
            default:
                return "An error occurred: \(code)"
            }
            
        case .invalidURL:
            return "Invalid request URL. Please contact support."
            
        case .invalidBody:
            return "Invalid request data. Please try again."
            
        case .emptyData:
            return "No data was received from the server."
            
        case .invalidJSON:
            return "There was an issue processing the server response."
            
        case .notConfigured:
            return "The app is not properly configured. Please restart the app."
            
        default:
            return "An unexpected error occurred."
        }
    } else {
        return "An error occurred: \(error.localizedDescription)"
    }
}
```

### Error Handling in Combine Publisher Chain

```swift
// Using the mapErrorToAPIError extension with Combine
URLSession.shared.dataTaskPublisher(for: url)
    .map { $0.data }
    .decode(type: YourModel.self, decoder: JSONDecoder())
    .mapErrorToAPIError() // Converts all errors to APIError
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("Error: \(handleAPIError(error))")
            }
        },
        receiveValue: { model in
            // Use the decoded model
        }
    )
    .store(in: &cancellables)
```

---

This guide covers the basic usage patterns for UDFNetworking. For more advanced features and configurations, please refer to the API documentation.

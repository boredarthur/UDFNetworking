//
//  APIEndpointTests.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 10.03.2025.
//

import XCTest
@testable import UDFNetworking

final class APIEndpointTests: BaseTests {
    
    // MARK: - Basic Endpoint Tests
    
    func testStringEndpoint() {
        // Given
        let endpointString = "/users"
        
        // When
        let endpoint: APIEndpoint = endpointString
        
        // Then
        XCTAssertEqual(endpoint.rawValue, "/users", "String should be usable as an APIEndpoint")
    }
    
    func testEnumEndpoint() {
        // Given
        enum TestEndpoints: String, APIEndpoint {
            case users = "/users"
            case profile = "/profile"
        }
        
        // When
        let endpoint = TestEndpoints.users
        
        // Then
        XCTAssertEqual(endpoint.rawValue, "/users", "Enum should provide the correct endpoint path")
    }
    
    // MARK: - Parameter Substitution Tests
    
    func testParameterSubstitution() {
        // Given
        let templateEndpoint = "/users/{id}/posts/{postId}"
        
        // When
        let actualEndpoint = templateEndpoint.substitutingParameters([
            "id": "123",
            "postId": "456"
        ])
        
        // Then
        XCTAssertEqual(actualEndpoint, "/users/123/posts/456", "Parameters should be substituted correctly")
    }
    
    func testPartialParameterSubstitution() {
        // Given
        let templateEndpoint = "/users/{id}/posts/{postId}"
        
        // When
        let actualEndpoint = templateEndpoint.substitutingParameters([
            "id": "123"
        ])
        
        // Then
        XCTAssertEqual(actualEndpoint, "/users/123/posts/{postId}", "Only provided parameters should be substituted")
    }
    
    func testNoParameterSubstitution() {
        // Given
        let templateEndpoint = "/users/{id}/posts/{postId}"
        
        // When
        let actualEndpoint = templateEndpoint.substitutingParameters([:])
        
        // Then
        XCTAssertEqual(actualEndpoint, templateEndpoint, "No substitution should occur with empty parameters")
    }
    
    // MARK: - URL Creation Tests
    
    func testURLCreation() {
        // Given
        let baseURL = URL(string: "https://api.example.com")!
        let endpoint = "/users/123"
        
        // When
        let url = endpoint.url(with: baseURL)
        
        // Then
        XCTAssertNotNil(url, "URL should be created successfully")
        XCTAssertEqual(url?.absoluteString, "https://api.example.com/users/123", "URL should be correctly formed")
    }
    
    func testURLCreationWithParameters() {
        // Given
        let baseURL = URL(string: "https://api.example.com")!
        let endpoint = "/users/{id}/posts/{postId}"
        
        // When
        let url = endpoint.url(with: baseURL, parameters: [
            "id": "123",
            "postId": "456"
        ])
        
        // Then
        XCTAssertNotNil(url, "URL should be created successfully")
        XCTAssertEqual(url?.absoluteString, "https://api.example.com/users/123/posts/456", "URL should include substituted parameters")
    }
    
    func testFullPathCreation() {
        // Given
        let baseURL = URL(string: "https://api.example.com")!
        let endpoint = "/users/123"
        
        // When
        let path = endpoint.fullPath(with: baseURL)
        
        // Then
        XCTAssertEqual(path, "https://api.example.com/api/users/123", "Default API path should be included")
        
        // When using a custom API path
        let customPath = endpoint.fullPath(with: baseURL, apiPath: "/v2")
        
        // Then
        XCTAssertEqual(customPath, "https://api.example.com/v2/users/123", "Custom API path should be used")
    }
    
    // MARK: - Complex Endpoint Tests
    
    func testComplexParameterizedEndpoint() {
        // Given
        enum ComplexEndpoints: APIEndpoint {
            case user(id: Int)
            case userPosts(userId: Int, limit: Int?)
            case search(query: String, filters: [String: String])
            
            var rawValue: String {
                switch self {
                case let .user(id):
                    return "/users/\(id)"
                case let .userPosts(userId, limit):
                    if let limit = limit {
                        return "/users/\(userId)/posts?limit=\(limit)"
                    } else {
                        return "/users/\(userId)/posts"
                    }
                case let .search(query, filters):
                    var path = "/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
                    for (key, value) in filters {
                        path += "&\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value)"
                    }
                    return path
                }
            }
        }
        
        // When
        let userEndpoint = ComplexEndpoints.user(id: 123)
        let postsEndpoint = ComplexEndpoints.userPosts(userId: 456, limit: 10)
        let searchEndpoint = ComplexEndpoints.search(query: "test query", filters: ["category": "technology", "sort": "date"])
        
        // Then
        XCTAssertEqual(userEndpoint.rawValue, "/users/123", "User endpoint should have correct format")
        XCTAssertEqual(postsEndpoint.rawValue, "/users/456/posts?limit=10", "Posts endpoint should include query parameter")
        XCTAssertTrue(searchEndpoint.rawValue.contains("/search?q=test%20query"), "Search endpoint should URL encode the query")
        XCTAssertTrue(searchEndpoint.rawValue.contains("category=technology"), "Search endpoint should include filters")
    }
    
    func testEndpointEquality() {
        // Given
        enum TestEndpoints: String, APIEndpoint, Equatable {
            case users = "/users"
            case profile = "/profile"
        }
        
        // When
        let endpoint1 = TestEndpoints.users
        let endpoint2 = TestEndpoints.users
        let endpoint3 = TestEndpoints.profile
        
        // Then
        XCTAssertEqual(endpoint1, endpoint2, "Same enum cases should be equal")
        XCTAssertNotEqual(endpoint1, endpoint3, "Different enum cases should not be equal")
        
        // String endpoints
        let stringEndpoint1: APIEndpoint = "/users"
        let stringEndpoint2: APIEndpoint = "/users"
        let stringEndpoint3: APIEndpoint = "/profile"
        
        // Then
        XCTAssertEqual(stringEndpoint1.rawValue, stringEndpoint2.rawValue, "String endpoints with same value should have equal rawValues")
        XCTAssertNotEqual(stringEndpoint1.rawValue, stringEndpoint3.rawValue, "String endpoints with different values should have different rawValues")
    }
}

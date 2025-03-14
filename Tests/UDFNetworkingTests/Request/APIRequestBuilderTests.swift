//
//  APIRequestBuilderTests.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 10.03.2025.
//

import XCTest
@testable import UDFNetworking

final class APIRequestBuilderTests: BaseTests {
    
    // Test endpoints
    enum TestEndpoints: APIEndpoint {
        case users
        case userDetails(id: Int)
        case search
        
        var rawValue: String {
            switch self {
            case .users:
                return "/users"
            case let .userDetails(id):
                return "/users/\(id)"
            case .search:
                return "/search"
            }
        }
    }
    
    // MARK: - Basic Builder Tests
    
    func testBasicRequestBuilding() {
        // Given
        let config = mockConfig
        API.configure(with: config)
        
        // When
        let requestContainer = try! APIRequest.Builder(endpoint: TestEndpoints.users)
            .method(.get)
            .build()
        
        // Then
        let request = requestContainer.urlRequest
        XCTAssertEqual(request.httpMethod, "GET", "HTTP method should be set correctly")
        XCTAssertEqual(request.url!.absoluteString, "https://mock.example.com/api/users", "URL should be constructed correctly")
        XCTAssertNil(request.httpBody, "GET request should not have a body")
    }
    
    func testRequestWithParameters() {
        // Given
        API.configure(with: mockConfig)
        
        // When - GET request with parameters
        let getRequest = try! APIRequest.Builder(endpoint: TestEndpoints.search)
            .method(.get)
            .parameters {
                URLQueryItem(name: "query", value: "test")
                URLQueryItem(name: "page", value: "1")
            }
            .build()
            .urlRequest
        
        // Then
        XCTAssertEqual(getRequest.httpMethod, "GET", "HTTP method should be GET")
        XCTAssertTrue(getRequest.url?.absoluteString.contains("query=test") ?? false, "URL should contain query parameters")
        XCTAssertTrue(getRequest.url?.absoluteString.contains("page=1") ?? false, "URL should contain all parameters")
        XCTAssertNil(getRequest.httpBody, "GET request should not have a body")
        
        // When - POST request with parameters
        let postRequest = try! APIRequest.Builder(endpoint: TestEndpoints.users)
            .method(.post)
            .parameters {
                URLQueryItem(name: "name", value: "John")
                URLQueryItem(name: "email", value: "john@example.com")
            }
            .build()
            .urlRequest
        
        // Then
        XCTAssertEqual(postRequest.httpMethod, "POST", "HTTP method should be POST")
        XCTAssertFalse(postRequest.url?.absoluteString.contains("name=John") ?? true, "URL should not contain parameters for POST")
        XCTAssertNotNil(postRequest.httpBody, "POST request should have a body")
        
        // Verify body contains the parameters
        if let body = postRequest.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            XCTAssertTrue(bodyString.contains("\"name\":\"John\""), "Body should contain the parameters as JSON")
            XCTAssertTrue(bodyString.contains("\"email\":\"john@example.com\""), "Body should contain all parameters")
        } else {
            XCTFail("Body should be valid JSON data")
        }
    }
    
    // MARK: - Headers Tests
    
    func testRequestWithHeaders() {
        // Given
        API.configure(with: mockConfig)
        
        // When
        let requestContainer = try? APIRequest.Builder(endpoint: TestEndpoints.users)
            .method(.get)
            .headers {
                // Using the HeaderItem type with the headers builder
                HeaderItem(.authorization, "Bearer token123")
                HeaderItem(.acceptLanguage, "en-US")
            }
            .build()
        
        // Then
        guard let request = requestContainer?.urlRequest else {
            XCTFail("Failed to build request")
            return
        }
        
        XCTAssertEqual(request.value(forHTTPHeaderField: HTTPHeaderField.authorization.rawValue), "Bearer token123", 
                       "Custom header should be set")
        XCTAssertEqual(request.value(forHTTPHeaderField: HTTPHeaderField.acceptLanguage.rawValue), "en-US", 
                       "All custom headers should be set")
        
        // Default headers from configuration should also be present
        for (key, value) in mockConfig.defaultHeaders {
            XCTAssertEqual(request.value(forHTTPHeaderField: key), value, 
                           "Default header from config should be present")
        }
    }
    
    func testHeaderOverrides() {
        // Given
        let config = APIConfiguration(
            baseURL: URL(string: "https://api.example.com")!,
            defaultHeaders: ["Content-Type": "application/json", "X-API-Version": "1.0"]
        )
        API.configure(with: config)
        
        // When - Override a default header
        let request = try! APIRequest.Builder(endpoint: TestEndpoints.users)
            .method(.get)
            .headers {
                HeaderItem(.contentType, "application/xml")
            }
            .build()
            .urlRequest
        
        // Then
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/xml", 
                       "Custom header should override default header")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-API-Version"), "1.0", 
                       "Other default headers should remain")
    }
    
    // MARK: - Parameter Substitution Tests
    
    func testEndpointParameterSubstitution() {
        // Given
        API.configure(with: mockConfig)
        
        // When - Using endpoint with integer ID
        let userId = 123
        let requestWithId = try? APIRequest.Builder(endpoint: TestEndpoints.userDetails(id: userId))
            .method(.get)
            .build()
            .urlRequest
        
        // Then
        let urlString = requestWithId?.url?.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("/users/123"), "URL should contain the numeric ID")
        
        // When - Using a different ID
        let anotherUserId = 456
        let requestWithAnotherId = try? APIRequest.Builder(endpoint: TestEndpoints.userDetails(id: anotherUserId))
            .method(.get)
            .build()
            .urlRequest
        
        // Then
        let anotherUrlString = requestWithAnotherId?.url?.absoluteString ?? ""
        XCTAssertTrue(anotherUrlString.contains("/users/456"), "URL should contain the different ID")
        XCTAssertFalse(anotherUrlString.contains("/users/123"), "URL should not contain the previous ID")
    }
    
    // MARK: - Custom Configuration Tests
    
    func testCustomConfiguration() {
        // Given
        let defaultConfig = mockConfig
        API.configure(with: defaultConfig)
        
        let customConfig = APIConfiguration(
            baseURL: URL(string: "https://custom.example.com")!,
            timeoutInterval: 60,
            defaultHeaders: ["X-Custom-Header": "CustomValue"]
        )
        
        // When
        let requestWithDefaultConfig = try! APIRequest.Builder(endpoint: TestEndpoints.users)
            .method(.get)
            .build()
            .urlRequest
        
        let requestWithCustomConfig = try? APIRequest.Builder(endpoint: TestEndpoints.users)
            .method(.get)
            .build(with: customConfig)
            .urlRequest
        
        // Then
        XCTAssertTrue(requestWithDefaultConfig.url?.absoluteString.starts(with: defaultConfig.baseURL.absoluteString) ?? false, 
                      "Default request should use default configuration")
        
        XCTAssertTrue(requestWithCustomConfig?.url?.absoluteString.starts(with: customConfig.baseURL.absoluteString) ?? false, 
                      "Custom request should use custom configuration")
        
        XCTAssertEqual(requestWithCustomConfig?.value(forHTTPHeaderField: "X-Custom-Header"), "CustomValue", 
                       "Custom request should use custom headers")
    }
    
    // MARK: - Timeout and Cache Policy Tests
    
    func testTimeoutAndCachePolicy() {
        // Given
        API.configure(with: mockConfig)
        
        // When
        let request = try! APIRequest.Builder(endpoint: TestEndpoints.users)
            .method(.get)
            .cachePolicy(.returnCacheDataDontLoad)
            .timeoutInterval(120)
            .build()
            .urlRequest
        
        // Then
        XCTAssertEqual(request.timeoutInterval, 120, "Custom timeout interval should be set")
        XCTAssertEqual(request.cachePolicy, .returnCacheDataDontLoad, "Custom cache policy should be set")
    }
    
    // MARK: - URL Session Tests
    
    func testCustomURLSession() {
        // Given
        API.configure(with: mockConfig)
        
        // Configure a custom session
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        let customSession = URLSession(configuration: configuration)
        
        // When
        let requestContainer = try! APIRequest.Builder(endpoint: TestEndpoints.users)
            .method(.get)
            .build(session: customSession)
        
        // Then
        XCTAssertNotEqual(requestContainer.session, URLSession.shared, "Custom session should be different from shared session")
    }
    
    // MARK: - Error Handling Tests
    
    func testMissingConfiguration() {
        // Given
        API.reset()
        
        // When/Then
        do {
            _ = try APIRequest.Builder(endpoint: TestEndpoints.users)
                .method(.get)
                .build()
            
            XCTFail("Building a request without configuration should throw an error")
        } catch let error as APIError {
            XCTAssertEqual(error.localizedDescription, APIError.notConfigured.localizedDescription, 
                           "Should throw notConfigured error")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Parameters Builder Tests
    
    func testParametersBuilder() {
        // Given
        API.configure(with: mockConfig)
        
        // Define helper variables to make the test clearer
        let alwaysPresent = "present"
        let conditionalValue: String? = "exists"
        let nilValue: String? = nil
        
        // When - Using conditional parameters
        let request = try! APIRequest.Builder(endpoint: TestEndpoints.search)
            .method(.get)
            .parameters {
                URLQueryItem(name: "always", value: alwaysPresent)
                
                if let value = conditionalValue {
                    URLQueryItem(name: "conditional", value: value)
                }
                
                if let value = nilValue {
                    URLQueryItem(name: "skipped", value: value)
                }
            }
            .build()
            .urlRequest
        
        // Then
        guard let urlString = request.url?.absoluteString else {
            XCTFail("Failed to build request URL")
            return
        }
        
        XCTAssertTrue(urlString.contains("always=present"), "Non-conditional parameter should be present")
        XCTAssertTrue(urlString.contains("conditional=exists"), "Conditional parameter with value should be present")
        XCTAssertFalse(urlString.contains("skipped"), "Conditional parameter without value should be skipped")
    }
    
    func testEmptyParameters() {
        // Given
        API.configure(with: mockConfig)
        
        // When
        let request = try! APIRequest.Builder(endpoint: TestEndpoints.users)
            .method(.get)
            .parameters { } // Empty parameters
            .build()
            .urlRequest
        
        // Then
        XCTAssertFalse(request.url?.absoluteString.contains("?") ?? true, 
                       "URL should not have query string with empty parameters")
    }
}

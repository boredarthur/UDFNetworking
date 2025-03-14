//
//  URLRequestExtensionsTests.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 14.03.2025.
//

import XCTest
@testable import UDFNetworking

final class URLRequestExtensionsTests: BaseTests {
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        
        // Configure API with a known base URL for most tests
        let baseURL = URL(string: "https://api.example.com")!
        let config = APIConfiguration(baseURL: baseURL)
        API.configure(with: config)
    }
    
    override func tearDown() {
        API.reset()
        super.tearDown()
    }
    
    // MARK: - Request Creation Tests
    
    func testBasicRequestCreation() throws {
        // Define a simple test endpoint
        enum TestEndpoints: APIEndpoint {
            case test
            
            var rawValue: String {
                return "/test"
            }
        }
        
        // Create a request
        let request = try URLRequest.request(for: TestEndpoints.test)
        
        // Verify the request properties
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/test")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertNil(request.httpBody)
        
        // Verify default headers are applied
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        
        // Verify the date header is added
        XCTAssertNotNil(request.value(forHTTPHeaderField: URLParameter.currentDatetime.rawValue.lowercased()))
    }
    
    func testRequestCreationWithURLEncoding() throws {
        // Define a test endpoint with special characters
        enum TestEndpoints: APIEndpoint {
            case search(query: String)
            
            var rawValue: String {
                switch self {
                case .search(let query):
                    return "/search/\(query)"
                }
            }
        }
        
        // Create a request with a query that needs URL encoding
        let request = try URLRequest.request(for: TestEndpoints.search(query: "test query with spaces"))
        
        // Verify the request URL is properly encoded
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/search/test%20query%20with%20spaces")
    }
    
    func testRequestCreationWithQueryParameters() throws {
        // Define a simple test endpoint
        enum TestEndpoints: APIEndpoint {
            case users
            
            var rawValue: String {
                return "/users"
            }
        }
        
        // Create a request with query parameters
        let request = try URLRequest.request(
            for: TestEndpoints.users,
            queryItems: {
                URLQueryItem(name: "page", value: "1")
                URLQueryItem(name: "limit", value: "20")
                URLQueryItem(name: "sort", value: "name")
            }
        )
        
        // Verify the request URL contains the query parameters
        let urlString = request.url?.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("page=1"))
        XCTAssertTrue(urlString.contains("limit=20"))
        XCTAssertTrue(urlString.contains("sort=name"))
    }
    
    func testRequestCreationWithDifferentHTTPMethod() throws {
        // Define a simple test endpoint
        enum TestEndpoints: APIEndpoint {
            case users
            
            var rawValue: String {
                return "/users"
            }
        }
        
        // Create a POST request
        let request = try URLRequest.request(
            for: TestEndpoints.users,
            httpMethod: .post
        )
        
        // Verify the request method is POST
        XCTAssertEqual(request.httpMethod, "POST")
    }
    
    func testRequestCreationWithPostAndQueryItems() throws {
        // Define a simple test endpoint
        enum TestEndpoints: APIEndpoint {
            case users
            
            var rawValue: String {
                return "/users"
            }
        }
        
        // Create a POST request with body parameters
        let request = try URLRequest.request(
            for: TestEndpoints.users,
            httpMethod: .post,
            queryItems: {
                URLQueryItem(name: "name", value: "John Doe")
                URLQueryItem(name: "email", value: "john@example.com")
            }
        )
        
        // Verify the request method is POST
        XCTAssertEqual(request.httpMethod, "POST")
        
        // Verify the query parameters are converted to a JSON body
        XCTAssertNotNil(request.httpBody)
        
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            XCTAssertTrue(bodyString.contains("\"name\":\"John Doe\""))
            XCTAssertTrue(bodyString.contains("\"email\":\"john@example.com\""))
        } else {
            XCTFail("Request should have a body")
        }
    }
    
    func testRequestCreationWithCustomCachePolicy() throws {
        // Create a request with a custom cache policy
        let request = try URLRequest.request(
            for: "test",
            cachePolicy: .returnCacheDataElseLoad
        )
        
        // Verify the cache policy is set correctly
        XCTAssertEqual(request.cachePolicy, .returnCacheDataElseLoad)
    }
    
    func testRequestCreationWithCustomTimeout() throws {
        // Create a request with a custom timeout
        let customTimeout: TimeInterval = 60
        let request = try URLRequest.request(
            for: "test",
            timeoutInterval: customTimeout
        )
        
        // Verify the timeout is set correctly
        XCTAssertEqual(request.timeoutInterval, customTimeout)
    }
    
    // MARK: - Set JSON Body Tests
    
    func testSetJSONBody() throws {
        // Create a basic request
        var request = URLRequest(url: URL(string: "https://example.com")!)
        
        // Define a test model
        struct TestModel: Codable, Equatable {
            let id: Int
            let name: String
        }
        
        // Set a JSON body
        let testModel = TestModel(id: 123, name: "Test")
        try request.setJSONBody(testModel)
        
        // Verify the body was set correctly
        XCTAssertNotNil(request.httpBody)
        
        // Verify the Content-Type header was set
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        
        // Decode the body back to verify it's correctly encoded
        if let body = request.httpBody {
            let decodedModel = try JSONDecoder().decode(TestModel.self, from: body)
            XCTAssertEqual(decodedModel, testModel)
        } else {
            XCTFail("Request should have a body")
        }
    }
    
    func testSetJSONBodyWithCustomEncoder() throws {
        // Create a basic request
        var request = URLRequest(url: URL(string: "https://example.com")!)
        
        // Define a test model with a date
        struct DateTestModel: Codable {
            let date: Date
            let name: String
        }
        
        // Create a custom encoder with a specific date encoding strategy
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        // Set a JSON body with the custom encoder
        let date = ISO8601DateFormatter().date(from: "2025-03-14T12:00:00Z")!
        let testModel = DateTestModel(date: date, name: "Test")
        try request.setJSONBody(testModel, encoder: encoder)
        
        // Verify the body contains ISO8601 formatted date
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            XCTAssertTrue(bodyString.contains("2025-03-14T12:00:00Z"))
        } else {
            XCTFail("Request should have a body")
        }
    }
    
    // MARK: - Authorization Tests
    
    func testAddAuthorization() {
        // Create a basic request
        var request = URLRequest(url: URL(string: "https://example.com")!)
        
        // Add authorization header
        let token = "Bearer test-token"
        _ = request.addAuthorization(token)
        
        // Verify the authorization header was set
        XCTAssertEqual(request.value(forHTTPHeaderField: HTTPHeaderField.authorization.rawValue), token)
    }
    
    // MARK: - URL Query Item Builder Tests
    
    func testURLQueryItemBuilderBasic() {
        // Create a function that uses the builder
        func buildQueryItems(@URLRequest.URLQueryItemBuilder builder: () -> [URLQueryItem]) -> [URLQueryItem] {
            return builder()
        }
        
        // Use the builder with basic items
        let items = buildQueryItems {
            URLQueryItem(name: "param1", value: "value1")
            URLQueryItem(name: "param2", value: "value2")
        }
        
        // Verify the items were built correctly
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].name, "param1")
        XCTAssertEqual(items[0].value, "value1")
        XCTAssertEqual(items[1].name, "param2")
        XCTAssertEqual(items[1].value, "value2")
    }
    
    func testURLQueryItemBuilderWithConditionals() {
        // Create a function that uses the builder
        func buildQueryItems(@URLRequest.URLQueryItemBuilder builder: () -> [URLQueryItem]) -> [URLQueryItem] {
            return builder()
        }
        
        // Use the builder with conditional items
        let includeOptional = true
        let items = buildQueryItems {
            URLQueryItem(name: "required", value: "always")
            
            if includeOptional {
                URLQueryItem(name: "optional", value: "included")
            }
        }
        
        // Verify the conditional item was included
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].name, "required")
        XCTAssertEqual(items[1].name, "optional")
        
        // Test with the condition as false
        let excludeOptional = false
        let filteredItems = buildQueryItems {
            URLQueryItem(name: "required", value: "always")
            
            if excludeOptional {
                URLQueryItem(name: "optional", value: "excluded")
            }
        }
        
        // Verify the conditional item was excluded
        XCTAssertEqual(filteredItems.count, 1)
        XCTAssertEqual(filteredItems[0].name, "required")
    }
    
    func testURLQueryItemBuilderWithArrays() {
        // Create a function that uses the builder
        func buildQueryItems(@URLRequest.URLQueryItemBuilder builder: () -> [URLQueryItem]) -> [URLQueryItem] {
            return builder()
        }
        
        // Use the builder with arrays of items
        let firstGroup = [
            URLQueryItem(name: "group1-item1", value: "value1"),
            URLQueryItem(name: "group1-item2", value: "value2")
        ]
        
        let secondGroup = [
            URLQueryItem(name: "group2-item1", value: "value3"),
            URLQueryItem(name: "group2-item2", value: "value4")
        ]
        
        let items = buildQueryItems {
            firstGroup
            secondGroup
        }
        
        // Verify all items from both arrays were included
        XCTAssertEqual(items.count, 4)
        XCTAssertEqual(items[0].name, "group1-item1")
        XCTAssertEqual(items[1].name, "group1-item2")
        XCTAssertEqual(items[2].name, "group2-item1")
        XCTAssertEqual(items[3].name, "group2-item2")
    }
    
    // MARK: - Error Tests
    
    func testRequestCreationWithoutAPIConfiguration() {
        // Reset API configuration
        API.reset()
        
        // Attempt to create a request without configuration
        XCTAssertThrowsError(try URLRequest.request(for: "test")) { error in
            XCTAssertEqual(error as? APIError, APIError.notConfigured)
        }
    }
    
    func testSetJSONBodyWithInvalidJSON() {
        // Create a basic request
        var request = URLRequest(url: URL(string: "https://example.com")!)
        
        // Create a class that can't be encoded to JSON
        class NonEncodable {}
        
        // Create a struct that will fail to encode
        struct InvalidModel: Encodable {
            let invalidProperty: NonEncodable = NonEncodable()
            
            func encode(to encoder: Encoder) throws {
                // This will fail since NonEncodable can't be encoded
                _ = encoder.container(keyedBy: CodingKeys.self)
                // Deliberately throw an encoding error to simulate failure
                throw EncodingError.invalidValue(
                    invalidProperty,
                    EncodingError.Context(
                        codingPath: [CodingKeys.invalidProperty],
                        debugDescription: "Cannot encode NonEncodable"
                    )
                )
            }
            
            enum CodingKeys: String, CodingKey {
                case invalidProperty
            }
        }
        
        // Try to encode the invalid model
        XCTAssertThrowsError(try request.setJSONBody(InvalidModel())) { error in
            // Verify it's the right type of error
            XCTAssertEqual(error as? APIError, APIError.invalidBody)
        }
    }
}

//
//  APITests.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 06.03.2025.
//

import XCTest
@testable import UDFNetworking

enum TestAPIClientEndpoints: String, APIEndpoint {
    case test = "/test-endpoint"
}

struct TestResponse: Decodable {
    let success: Bool
}

enum TestAPIClient: BaseAPIClientProtocol {
    static func makeTestRequest(session: URLSession) async throws -> TestResponse {
        let url = URL(string: "https://example.com/api/test-endpoint")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        
        return try await withCheckedThrowingContinuation { continuation in
            session.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let data = data else {
                    continuation.resume(throwing: APIError.emptyData)
                    return
                }
                
                do {
                    if let httpResponse = response as? HTTPURLResponse {
                        print("Response status code: \(httpResponse.statusCode)")
                    }
                    
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Response data: \(jsonString)")
                    }
                    
                    let result = try JSONDecoder().decode(TestResponse.self, from: data)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }.resume()
        }
    }
}

final class APITests: BaseTests {
    // MARK: - Configuration Management Tests
    
    func testConfigurationManagement() {
        // Given
        let testConfig = APIConfiguration(
            baseURL: URL(string: "https://api.test.com")!,
            timeoutInterval: 60,
            logLevel: .debug
        )
        
        // When: Initially API should not be configured
        API.reset()
        
        // Then
        XCTAssertFalse(API.isConfigured(), "API should not be configured after reset")
        XCTAssertNil(API.configuration, "Configuration should be nil after reset")
        
        // When: We configure the API
        API.configure(with: testConfig)
        
        // Then
        XCTAssertTrue(API.isConfigured(), "API should be configured after calling configure()")
        XCTAssertNotNil(API.configuration, "Configuration should not be nil after configure")
        XCTAssertEqual(API.configuration.baseURL, testConfig.baseURL, "API.configuration should have the same baseURL")
        XCTAssertEqual(API.configuration.timeoutInterval, testConfig.timeoutInterval, "API.configuration should have the same timeoutInterval")
        XCTAssertEqual(API.configuration.logLevel, testConfig.logLevel, "API.configuration should have the same logLevel")
    }
    
    func testConfigurationOverride() {
        // Given
        let initialConfig = APIConfiguration(
            baseURL: URL(string: "https://initial.example.com")!,
            logLevel: .none
        )
        
        let newConfig = APIConfiguration(
            baseURL: URL(string: "https://new.example.com")!,
            logLevel: .verbose
        )
        
        // When: Configure with initial config, then override with new config
        API.configure(with: initialConfig)
        API.configure(with: newConfig)
        
        // Then
        XCTAssertEqual(API.configuration.baseURL, newConfig.baseURL, "API.configuration should have the updated baseURL")
        XCTAssertEqual(API.configuration.logLevel, newConfig.logLevel, "API.configuration should have the updated logLevel")
    }
    
    // MARK: - Logging Level Tests
    
    func testLoggingLevelUpdate() {
        // Given
        let config = APIConfiguration(
            baseURL: URL(string: "https://api.example.com")!,
            logLevel: .none
        )
        API.configure(with: config)
        
        // When: Update the logging level
        API.setLoggingLevel(.verbose)
        
        // Then
        XCTAssertEqual(API.configuration.logLevel, .verbose, "API.configuration.logLevel should be updated")
        XCTAssertEqual(config.logLevel, .verbose, "Original config object should also be updated")
    }
    
    // MARK: - Error Handling Tests
    
    // Create a nested enum that conforms to the protocol for error testing
    enum ErrorTestClient: BaseAPIClientProtocol {
        enum Endpoints: String, APIEndpoint {
            case test = "/test"
        }
        
        struct TestResponse: Decodable {
            let success: Bool
        }
        
        static func makeTestRequest() async throws -> TestResponse {
            let request = try APIRequest.Builder(endpoint: Endpoints.test)
                .method(.get)
                .build()
            
            return try await performRequest(with: request.urlRequest)
        }
    }
    
    func testAPINotConfiguredError() async {
        // Given: API is not configured
        API.reset()
        
        // When/Then: Attempting operations without configuration should fail appropriately
        do {
            _ = try await ErrorTestClient.makeTestRequest()
            XCTFail("Request should fail when API is not configured")
        } catch let error as APIError {
            // Verify we get the expected error type
            XCTAssertEqual(error.localizedDescription, APIError.notConfigured.localizedDescription, 
                           "Should throw notConfigured error when API is not set up")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteRequestFlow() async {
        let testConfig = APIConfiguration(
            baseURL: URL(string: "https://example.com")!,
            defaultHeaders: ["X-API-Key": "test-key"],
            logLevel: .debug
        )
        API.configure(with: testConfig)
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: config)
        
        print("Protocol classes: \(String(describing: config.protocolClasses))")
        
        MockURLProtocol.requestHandler = { request in
            print("🔍 Mock handling URL: \(request.url?.absoluteString ?? "unknown")")
            
            // Create response with success data
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            
            let jsonData = try! JSONSerialization.data(withJSONObject: ["success": true])
            return (response, jsonData)
        }
        
        do {
            let url = URL(string: "https://example.com/api/test-endpoint")!
            let basicRequest = URLRequest(url: url)
            
            let (data, response) = try await mockSession.data(for: basicRequest)
            let httpResponse = response as? HTTPURLResponse
            
            print("Direct test status: \(httpResponse?.statusCode ?? 0)")
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Direct test data: \(jsonString)")
            }
            
            XCTAssertEqual(httpResponse?.statusCode, 200, "Mock should respond with 200")
            
            let result = try await TestAPIClient.makeTestRequest(session: mockSession)
            XCTAssertTrue(result.success, "Response should contain expected data")
        } catch {
            XCTFail("Request failed with error: \(error)")
            
            print("Error details: \(error)")
            if let apiError = error as? APIError {
                print("API Error type: \(apiError)")
            }
        }
    }
}

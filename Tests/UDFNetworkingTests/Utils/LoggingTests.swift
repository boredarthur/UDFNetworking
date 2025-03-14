//
//  LoggingTests.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 14.03.2025.
//

import XCTest
@testable import UDFNetworking

final class LoggingTests: BaseTests {
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        // Make sure we start with a clean state
        APILogger.setLogLevel(.none)
    }
    
    override func tearDown() {
        // Reset logging level to not affect other tests
        APILogger.setLogLevel(.none)
        super.tearDown()
    }
    
    // MARK: - Log Level Tests
    
    func testLogLevelConfiguration() {
        // Test each log level
        APILogger.setLogLevel(.none)
        XCTAssertEqual(APILogger.logLevel, .none)
        
        APILogger.setLogLevel(.error)
        XCTAssertEqual(APILogger.logLevel, .error)
        
        APILogger.setLogLevel(.debug)
        XCTAssertEqual(APILogger.logLevel, .debug)
        
        APILogger.setLogLevel(.verbose)
        XCTAssertEqual(APILogger.logLevel, .verbose)
    }
    
    func testLogLevelWithAPIConfiguration() {
        // Test that log level is updated when API is configured
        let config = APIConfiguration(
            baseURL: URL(string: "https://example.com")!,
            logLevel: .debug
        )
        
        API.configure(with: config)
        XCTAssertEqual(APILogger.logLevel, .debug)
        
        // Test updating the log level through API
        API.setLoggingLevel(.verbose)
        XCTAssertEqual(APILogger.logLevel, .verbose)
        XCTAssertEqual(config.logLevel, .verbose) // Config should be updated too
    }
    
    // MARK: - Request Logging Tests
    
    func testRequestLogging() {
        // Since we can't easily capture console output in a unit test,
        // we'll focus on testing that the logger doesn't crash and
        // respects the configured log level
        
        // Create a sample request
        var request = URLRequest(url: URL(string: "https://example.com/test")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create some sample JSON data
        let jsonObject = ["name": "Test", "id": 123] as [String: Any]
        request.httpBody = try? JSONSerialization.data(withJSONObject: jsonObject)
        
        // Test with different log levels
        
        // None: Shouldn't log anything
        APILogger.setLogLevel(.none)
        APILogger.logRequest(request) // Should do nothing
        
        // Error: Shouldn't log requests
        APILogger.setLogLevel(.error)
        APILogger.logRequest(request) // Should do nothing
        
        // Debug: Should log basic request info
        APILogger.setLogLevel(.debug)
        APILogger.logRequest(request) // Should log method and URL
        
        // Verbose: Should log detailed request info
        APILogger.setLogLevel(.verbose)
        APILogger.logRequest(request) // Should log method, URL, headers, and body
    }
    
    func testResponseLogging() {
        // Create sample response components
        let url = URL(string: "https://example.com/test")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        let data = """
        {
            "id": 123,
            "name": "Test Response"
        }
        """.data(using: .utf8)!
        
        // Test with different log levels
        
        // None: Shouldn't log anything
        APILogger.setLogLevel(.none)
        APILogger.logResponse(data: data, response: response, error: nil, url: url) // Should do nothing
        
        // Error: Shouldn't log success responses
        APILogger.setLogLevel(.error)
        APILogger.logResponse(data: data, response: response, error: nil, url: url) // Should do nothing
        
        // Debug: Should log basic response info
        APILogger.setLogLevel(.debug)
        APILogger.logResponse(data: data, response: response, error: nil, url: url) // Should log status and URL
        
        // Verbose: Should log detailed response info
        APILogger.setLogLevel(.verbose)
        APILogger.logResponse(data: data, response: response, error: nil, url: url) // Should log status, URL, headers, and body
    }
    
    func testErrorResponseLogging() {
        // Create sample error response components
        let url = URL(string: "https://example.com/test")!
        let errorResponse = HTTPURLResponse(
            url: url,
            statusCode: 404,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        let errorData = """
        {
            "error": "Not found",
            "message": "The requested resource was not found"
        }
        """.data(using: .utf8)!
        
        // Test with different log levels
        
        // None: Shouldn't log anything
        APILogger.setLogLevel(.none)
        APILogger.logResponse(data: errorData, response: errorResponse, error: nil, url: url) // Should do nothing
        
        // Error: Should log error responses
        APILogger.setLogLevel(.error)
        APILogger.logResponse(data: errorData, response: errorResponse, error: nil, url: url) // Should log error
        
        // Debug: Should log basic error info
        APILogger.setLogLevel(.debug)
        APILogger.logResponse(data: errorData, response: errorResponse, error: nil, url: url) // Should log error status and URL
        
        // Verbose: Should log detailed error info
        APILogger.setLogLevel(.verbose)
        APILogger.logResponse(data: errorData, response: errorResponse, error: nil, url: url) // Should log error status, URL, headers, and body
    }
    
    func testNetworkErrorLogging() {
        // Create a network error
        let url = URL(string: "https://example.com/test")!
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        
        // Test with different log levels
        
        // None: Shouldn't log anything
        APILogger.setLogLevel(.none)
        APILogger.logResponse(data: nil, response: nil, error: networkError, url: url) // Should do nothing
        
        // Error: Should log network errors
        APILogger.setLogLevel(.error)
        APILogger.logResponse(data: nil, response: nil, error: networkError, url: url) // Should log error
        
        // Debug and Verbose: Should log network errors
        APILogger.setLogLevel(.debug)
        APILogger.logResponse(data: nil, response: nil, error: networkError, url: url) // Should log error
    }
    
    // MARK: - Integration Tests
    
    func testIntegrationWithAPI() {
        // Test that the logger integrates correctly with the API configuration
        
        // Configure API with a specific log level
        let config = APIConfiguration(
            baseURL: URL(string: "https://example.com")!,
            logLevel: .verbose
        )
        API.configure(with: config)
        
        // Verify the log level was set correctly
        XCTAssertEqual(APILogger.logLevel, .verbose)
        
        // Update the log level through the API
        API.setLoggingLevel(.debug)
        
        // Verify both the logger and configuration were updated
        XCTAssertEqual(APILogger.logLevel, .debug)
        XCTAssertEqual(config.logLevel, .debug)
        
        // Reset the API to reset the logger
        API.reset()
        
        // Verify the logger was reset to default level
        XCTAssertEqual(APILogger.logLevel, .error)
    }
}

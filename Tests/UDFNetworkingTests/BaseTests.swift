//
//  BaseTests.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 06.03.2025.
//

import XCTest
import Combine
@testable import UDFNetworking

/// Base class for all UDFNetworking test cases
/// Provides common setup, teardown, and utility methods
class BaseTests: XCTestCase {
    // Storage for Combine publishers to prevent premature cancellation
    var cancellables: Set<AnyCancellable> = []
    
    // Default test timeout for asynchronous expectations
    let defaultTimeout: TimeInterval = 5.0
    
    /// URL session configured for mocking network responses
    var mockURLSession: URLSession!
    
    /// Standard URL session for real network calls
    var standardURLSession: URLSession!
    
    // MARK: - API Configurations
    
    /// Mock API configuration for unit tests
    var mockConfig: APIConfiguration {
        APIConfiguration(
            baseURL: URL(string: "https://mock.example.com/api")!,
            cdnURL: URL(string: "https://cdn.mock.example.com"),
            mediaCDNURL: URL(string: "https://media.mock.example.com"),
            timeoutInterval: 1.0,
            defaultHeaders: [
                "Content-Type": "application/json",
                "Accept": "application/json",
                "X-Client-ID": "test-client"
            ],
            logLevel: .none
        )
    }
    
    /// Real API configuration for integration tests with the Cat Facts API
    var catFactsConfig: APIConfiguration {
        APIConfiguration(
            baseURL: URL(string: "https://cat-fact.herokuapp.com")!,
            timeoutInterval: 30.0,
            defaultHeaders: [
                "Content-Type": "application/json",
                "Accept": "application/json"
            ],
            logLevel: .error
        )
    }
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        setupMockURLSession()
        setupStandardURLSession()
        
        API.configure(with: mockConfig)
        APILogger.setLogLevel(.none)
        
        cancellables.removeAll()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        MockURLProtocol.requestHandler = nil
        API.reset()
        
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Configures a URL session for mocking network responses
    func setupMockURLSession() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockURLSession = URLSession(configuration: configuration)
    }
    
    /// Creates a standard URL session for real network calls
    func setupStandardURLSession() {
        standardURLSession = URLSession(configuration: .default)
    }
    
    /// Registers a mock response for a specific URL pattern
    /// - Parameters:
    ///   - urlContains: String that should be contained in the URL
    ///   - statusCode: HTTP status code to return
    ///   - data: Response data to return
    ///   - headers: Response headers (optional)
    func registerMockResponse(
        urlContains: String,
        statusCode: Int = 200,
        data: Data,
        headers: [String: String] = ["Content-Type": "application/json"]
    ) {
        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""
            
            guard url.contains(urlContains) else {
                throw APIError.invalidURL
            }
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: "HTTP/2",
                headerFields: headers
            )!
            
            return (response, data)
        }
    }
    
    /// Creates mock JSON data from a dictionary
    /// - Parameter dict: Dictionary to convert to JSON
    /// - Returns: JSON data
    func mockJSONData(from dict: [String: Any]) -> Data {
        return try! JSONSerialization.data(withJSONObject: dict)
    }
    
    /// Helper to wait for async operations in tests that don't use async/await
    /// - Parameter timeout: Time to wait before continuing
    func waitForAsyncOperation(timeout: TimeInterval = 0.1) {
        let expectation = self.expectation(description: "Wait for async operation")
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout + 0.1)
    }
    
    /// Helper method to test a publisher by waiting for its completion
    /// - Parameters:
    ///   - publisher: The publisher to test
    ///   - timeout: Maximum time to wait
    ///   - file: File where the method is called (for better error messages)
    ///   - line: Line where the method is called (for better error messages)
    ///   - valueHandler: Handler called with the received value
    ///   - completionHandler: Handler called with the completion result
    func testPublisher<P: Publisher>(
        _ publisher: P,
        timeout: TimeInterval = 1.0,
        file: StaticString = #file,
        line: UInt = #line,
        valueHandler: @escaping (P.Output) -> Void,
        completionHandler: @escaping (Subscribers.Completion<P.Failure>) -> Void = { _ in }
    ) {
        let expectation = self.expectation(description: "Publisher completion")
        
        publisher
            .sink(
                receiveCompletion: { completion in
                    completionHandler(completion)
                    expectation.fulfill()
                },
                receiveValue: { value in
                    valueHandler(value)
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: timeout)
    }
}

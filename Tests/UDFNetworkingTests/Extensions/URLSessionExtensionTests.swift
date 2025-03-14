//
//  URLSessionExtensionsTests.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 14.03.2025.
//

import XCTest
import Combine
@testable import UDFNetworking

final class URLSessionExtensionsTests: BaseTests {
    // MARK: - ValidateDataTaskPublisher Tests
    
    func testValidateDataTaskPublisher() {
        // Set up expectations
        let expectation = XCTestExpectation(description: "Publisher should complete successfully")
        
        // Set up mock response with success
        let successData = """
        {
            "id": 1,
            "name": "Test Item"
        }
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            return (
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!,
                successData
            )
        }
        
        // Create request
        let request = URLRequest(url: URL(string: "https://example.com/test")!)
        
        // Test the publisher
        mockURLSession.validateDataTaskPublisher(request: request)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("Publisher should not fail: \(error)")
                    }
                },
                receiveValue: { data in
                    // Verify data matches what we sent
                    XCTAssertEqual(data, successData)
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testValidateDataTaskPublisherWithError() {
        // Set up expectations
        let expectation = XCTestExpectation(description: "Publisher should fail with error")
        
        // Set up mock response with error
        let errorData = """
        {
            "error": "Bad Request",
            "message": "Invalid parameters"
        }
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            return (
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 400,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!,
                errorData
            )
        }
        
        // Create request
        let request = URLRequest(url: URL(string: "https://example.com/test")!)
        
        // Test the publisher
        mockURLSession.validateDataTaskPublisher(request: request)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        XCTFail("Publisher should fail with error")
                    case .failure(let error):
                        // Expect an APIError.statusCode
                        if let apiError = error as? APIError {
                            if case .statusCode(let code, _, _) = apiError {
                                XCTAssertEqual(code, 400)
                                expectation.fulfill()
                            } else {
                                XCTFail("Expected statusCode error but got: \(apiError)")
                            }
                        } else {
                            XCTFail("Expected APIError but got: \(error)")
                        }
                    }
                },
                receiveValue: { _ in
                    XCTFail("Publisher should not emit a value")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - URL Expiration Test
    
    func testHasUrlExpired() {
        // Set up expectations
        let validExpectation = XCTestExpectation(description: "Valid URL check completes")
        let expiredExpectation = XCTestExpectation(description: "Expired URL check completes")
        
        // Set up mock responses
        
        // For valid URL
        MockURLProtocol.requestHandler = { request in
            return (
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data()
            )
        }
        
        // Test valid URL
        let validURL = URL(string: "https://example.com/valid")!
        mockURLSession.hasUrlExpired(url: validURL) { expired in
            XCTAssertFalse(expired, "URL should not be expired")
            validExpectation.fulfill()
        }
        
        wait(for: [validExpectation], timeout: 1.0)
        
        // Set up for expired URL
        MockURLProtocol.requestHandler = { request in
            return (
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 404,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data()
            )
        }
        
        // Test expired URL
        let expiredURL = URL(string: "https://example.com/expired")!
        mockURLSession.hasUrlExpired(url: expiredURL) { expired in
            XCTAssertTrue(expired, "URL should be expired")
            expiredExpectation.fulfill()
        }
        
        wait(for: [expiredExpectation], timeout: 1.0)
    }
    
    func testHasUrlExpiredWithNetworkError() {
        // Set up expectation
        let expectation = XCTestExpectation(description: "Network error check completes")
        
        // Set up mock to throw network error
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        
        // Test URL with network error
        let url = URL(string: "https://example.com/test")!
        mockURLSession.hasUrlExpired(url: url) { expired in
            XCTAssertTrue(expired, "URL should be considered expired when network error occurs")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Helper Properties for Testing
    
    // This is a hack to help test download tasks
    // In real code, we wouldn't do this, but it helps us test without modifying production code
    private static var URLSession_mockDownloadURL: URL?
}

// Extension to support download task testing by providing the URL
extension URLSession {
    private static var swizzled = false
    
    static func swizzleForTesting() {
        guard !swizzled else { return }
        swizzled = true
        
        // Swizzle the downloadTask implementation for testing
        // This would be complex to implement properly
    }
}

//
//  PublisherExtensionsTests.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 14.03.2025.
//

import XCTest
import Combine
@testable import UDFNetworking

final class PublisherExtensionsTests: BaseTests {
    // MARK: - Test mapErrorToAPIError with different error types
    
    func testMapErrorToAPIErrorWithAPIError() {
        // Set up expectation
        let expectation = XCTestExpectation(description: "Publisher should complete with mapped error")
        
        // Create a failing publisher with an APIError
        let originalError = APIError.invalidURL
        let publisher = Fail<String, APIError>(error: originalError)
        
        // Apply the extension
        publisher
            .mapErrorToAPIError()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Should be the same APIError
                        XCTAssertEqual(error, originalError)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive a value")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testMapErrorToAPIErrorWithURLError() {
        // Set up expectation
        let expectation = XCTestExpectation(description: "Publisher should complete with mapped URL error")
        
        // Create a failing publisher with a URLError
        let originalError = URLError(.notConnectedToInternet)
        let publisher = Fail<String, Error>(error: originalError)
        
        // Apply the extension
        publisher
            .mapErrorToAPIError()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Should be mapped to APIError.networkError
                        if case .networkError(let underlyingError) = error {
                            XCTAssertEqual((underlyingError as? URLError)?.code, originalError.code)
                            expectation.fulfill()
                        } else {
                            XCTFail("Expected networkError but got \(error)")
                        }
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive a value")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testMapErrorToAPIErrorWithNSError() {
        // Set up expectation
        let expectation = XCTestExpectation(description: "Publisher should complete with mapped NS error")
        
        // Create a failing publisher with an NSError
        let originalError = NSError(domain: "TestDomain", code: 42, userInfo: ["test": "info"])
        let publisher = Fail<String, Error>(error: originalError)
        
        // Apply the extension
        publisher
            .mapErrorToAPIError()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Should be mapped to APIError.statusCode
                        if case .statusCode(let code, _, let meta) = error {
                            XCTAssertEqual(code, 42)
                            XCTAssertEqual(meta?["test"] as? String, "info")
                            expectation.fulfill()
                        } else {
                            XCTFail("Expected statusCode but got \(error)")
                        }
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive a value")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testMapErrorToAPIErrorWithCustomError() {
        // Set up expectation
        let expectation = XCTestExpectation(description: "Publisher should complete with mapped custom error")
        
        // Create a custom error
        struct CustomTestError: Error, LocalizedError {
            var errorDescription: String? { "Custom test error" }
        }
        
        // Create a failing publisher with a custom error
        let originalError = CustomTestError()
        let publisher = Fail<String, Error>(error: originalError)
        
        // Apply the extension
        publisher
            .mapErrorToAPIError()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        if case .statusCode(let code, let underlyingError, _) = error {
                            XCTAssertEqual(code, 1)
                            XCTAssertTrue(underlyingError is CustomTestError)
                            expectation.fulfill()
                        } else {
                            XCTFail("Expected statusCode but got \(error)")
                        }
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive a value")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test with a complete publisher chain
    
    func testMapErrorToAPIErrorInPublisherChain() {
        // Set up expectation
        let expectation = XCTestExpectation(description: "Publisher chain should complete with mapped error")
        
        // Create a URL that will fail
        let url = URL(string: "https://invalid-url-that-will-fail.xyz")!
        
        // Set up the URL session to use our mock protocol
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: sessionConfig)
        
        // Configure the mock to throw a network error
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        
        // Create the publisher chain
        session.dataTaskPublisher(for: url)
            .map { data, _ in data }
            .decode(type: String.self, decoder: JSONDecoder())
            .mapErrorToAPIError()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Network error should be mapped correctly
                        if case .networkError(let underlyingError) = error {
                            XCTAssertEqual((underlyingError as? URLError)?.code, .notConnectedToInternet)
                            expectation.fulfill()
                        } else {
                            XCTFail("Expected networkError but got \(error)")
                        }
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive a value")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test with successful publisher
    
    func testSuccessfulPublisherWithErrorMapping() {
        // Set up expectation
        let expectation = XCTestExpectation(description: "Publisher should complete successfully")
        
        // Create a successful publisher
        let publisher = Just("Success!")
            .setFailureType(to: Error.self)
            .mapErrorToAPIError()
        
        // The error mapping shouldn't affect successful publishers
        publisher
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        expectation.fulfill()
                    } else {
                        XCTFail("Publisher should complete successfully")
                    }
                },
                receiveValue: { value in
                    XCTAssertEqual(value, "Success!")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
}

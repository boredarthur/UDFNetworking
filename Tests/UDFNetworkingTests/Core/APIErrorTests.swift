//
//  APIErrorTests.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 10.03.2025.
//

import XCTest
@testable import UDFNetworking

final class APIErrorTests: BaseTests {
    
    // MARK: - Basic Error Properties Tests
    
    func testAPIErrorDescriptions() {
        // Test various API error types to ensure they have appropriate descriptions
        XCTAssertFalse(APIError.invalidURL.localizedDescription.isEmpty, "invalidURL should have a description")
        XCTAssertFalse(APIError.invalidBody.localizedDescription.isEmpty, "invalidBody should have a description")
        XCTAssertFalse(APIError.emptyData.localizedDescription.isEmpty, "emptyData should have a description")
        XCTAssertFalse(APIError.invalidJSON.localizedDescription.isEmpty, "invalidJSON should have a description")
        XCTAssertFalse(APIError.invalidResponse.localizedDescription.isEmpty, "invalidResponse should have a description")
        XCTAssertFalse(APIError.notConfigured.localizedDescription.isEmpty, "notConfigured should have a description")
    }
    
    func testStatusCodeError() {
        // Given
        let statusCode = 401
        let underlyingError = CustomError("Unauthorized access")
        let metadata: [String: Any] = ["request_id": "abc123", "timestamp": 1614556800]
        
        // When
        let error = APIError.statusCode(statusCode, underlyingError, metadata)
        
        // Then
        XCTAssertEqual(error.statusCode, statusCode, "statusCode property should match the provided code")
        XCTAssertEqual(error.localizedDescription, underlyingError.localizedDescription, "Description should match underlying error")
        XCTAssertEqual(error.meta?["request_id"] as? String, "abc123", "Metadata should be accessible")
        XCTAssertNotNil(error.underlyingError, "Underlying error should be accessible")
    }
    
    func testNetworkError() {
        // Given
        let urlError = URLError(.notConnectedToInternet)
        
        // When
        let error = APIError.networkError(urlError)
        
        // Then
        XCTAssertTrue(error.localizedDescription.contains("Network error"), "Description should indicate network error")
        XCTAssertEqual(error.underlyingError as? URLError, urlError, "Underlying error should be preserved")
    }
    
    func testCustomError() {
        // Given
        let message = "Custom error message"
        
        // When
        let error = APIError.custom(message)
        
        // Then
        XCTAssertEqual(error.localizedDescription, message, "Description should match the custom message")
    }
    
    // MARK: - Server Error Tests
    
    func testServerErrorParsing() {
        // Given: A server error response
        let statusCode = 422
        let errorResponse: [String: Any] = [
            "email": "Invalid email format",
            "password": "Password too short",
            "meta": [
                "request_id": "xyz789"
            ]
        ]
        let errorData = try! JSONSerialization.data(withJSONObject: errorResponse)
        
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com/api/test")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        
        // When
        let serverError = ServerError(data: errorData, response: response)
        
        // Then
        XCTAssertNotNil(serverError, "Server error should be created from valid error data")
        XCTAssertTrue(serverError?.errorDescription?.contains("email - Invalid email format") ?? false, 
                      "Error description should include field errors")
        XCTAssertTrue(serverError?.errorDescription?.contains("password - Password too short") ?? false, 
                      "Error description should include all error fields")
        XCTAssertEqual(serverError?.meta?["request_id"] as? String, "xyz789", "Metadata should be parsed correctly")
    }
    
    func testServerErrorWithInvalidData() {
        // Given: Invalid error data
        let invalidData = "Not JSON".data(using: .utf8)!
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com/api/test")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )!
        
        // When
        let serverError = ServerError(data: invalidData, response: response)
        
        // Then
        #if DEBUG
        // In debug mode, it should create an error with debug info
        XCTAssertNotNil(serverError, "Should create a debug error even with invalid data")
        XCTAssertTrue(serverError?.errorDescription?.contains("Status code: 500") ?? false, 
                      "Debug error should contain status code")
        #else
        // In production, it should return nil for invalid data
        XCTAssertNil(serverError, "Should return nil for invalid data in production")
        #endif
    }
    
    // MARK: - Error Mapping Tests
    
    func testErrorMappingFromURLError() {
        // Given
        let urlError = URLError(.timedOut)
        
        // When
        let apiError = mapToAPIError(urlError)
        
        // Then
        if case .networkError(let underlyingError) = apiError {
            XCTAssertEqual((underlyingError as? URLError)?.code, URLError.timedOut, 
                           "Should map to networkError with the original URLError")
        } else {
            XCTFail("URLError should map to .networkError")
        }
    }
    
    func testErrorMappingFromNSError() {
        // Given
        let nsError = NSError(domain: "TestDomain", code: 42, userInfo: nil)
        
        // When
        let apiError = mapToAPIError(nsError)
        
        // Then
        if case .statusCode(let code, let error, _) = apiError {
            XCTAssertEqual(code, 42, "Status code should match NSError code")
            XCTAssertEqual(error.localizedDescription, nsError.localizedDescription, 
                           "Error description should match original")
        } else {
            XCTFail("NSError should map to .statusCode")
        }
    }
    
    // Helper function to simulate the error mapping logic from Publisher+APIError
    private func mapToAPIError(_ error: Error) -> APIError {
        switch error {
        case let apiError as APIError:
            return apiError
            
        case let urlError as URLError:
            return .networkError(urlError)
            
        case let nsError as NSError:
            return .statusCode(nsError.code, nsError, nsError.userInfo)
            
        default:
            return .invalidResponse
        }
    }
    
    // MARK: - Integration Tests
    
    func testRequestValidationWithErrorResponse() {
        // Given
        let errorData = try! JSONSerialization.data(withJSONObject: ["error": "Bad request"])
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com/api/test")!,
            statusCode: 400,
            httpVersion: nil,
            headerFields: nil
        )!
        
        // When/Then
        do {
            _ = try RequestValidation.validate(errorData, response)
            XCTFail("Validation should fail for error status code")
        } catch let error as APIError {
            if case .statusCode(let code, _, _) = error {
                XCTAssertEqual(code, 400, "Status code should be preserved in the error")
            } else {
                XCTFail("Error should be of type .statusCode")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testRequestValidationWithSuccessResponse() {
        // Given
        let successData = try! JSONSerialization.data(withJSONObject: ["success": true])
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com/api/test")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        // When/Then
        do {
            let validatedData = try RequestValidation.validate(successData, response)
            XCTAssertEqual(validatedData, successData, "Validated data should match the input data")
        } catch {
            XCTFail("Validation should succeed for success status code: \(error)")
        }
    }
}

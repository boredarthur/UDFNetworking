//
//  RequestValidationTests.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 10.03.2025.
//

import XCTest
@testable import UDFNetworking

final class RequestValidationTests: BaseTests {
    
    // MARK: - Successful Validation Tests
    
    func testSuccessfulValidation() {
        // Given
        let successData = try! JSONSerialization.data(withJSONObject: ["success": true])
        let successResponse = HTTPURLResponse(
            url: URL(string: "https://example.com/api/test")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        // When/Then
        do {
            let validatedData = try RequestValidation.validate(successData, successResponse)
            XCTAssertEqual(validatedData, successData, "Validated data should match the input data")
        } catch {
            XCTFail("Validation should succeed for 200 status code: \(error)")
        }
    }
    
    // MARK: - Error Status Code Tests
    
    func testClientErrorStatusCode() {
        // Given
        let errorData = try! JSONSerialization.data(withJSONObject: ["error": "Bad Request"])
        let errorResponse = HTTPURLResponse(
            url: URL(string: "https://example.com/api/test")!,
            statusCode: 400,
            httpVersion: nil,
            headerFields: nil
        )!
        
        // When/Then
        do {
            _ = try RequestValidation.validate(errorData, errorResponse)
            XCTFail("Validation should fail for 4xx status code")
        } catch let error as APIError {
            switch error {
            case .statusCode(let statusCode, _, _):
                XCTAssertEqual(statusCode, 400, "Status code should be preserved in the error")
            default:
                XCTFail("Error should be of type .statusCode")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testServerErrorStatusCode() {
        // Given
        let errorData = try! JSONSerialization.data(withJSONObject: ["error": "Internal Server Error"])
        let errorResponse = HTTPURLResponse(
            url: URL(string: "https://example.com/api/test")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )!
        
        // When/Then
        do {
            _ = try RequestValidation.validate(errorData, errorResponse)
            XCTFail("Validation should fail for 5xx status code")
        } catch let error as APIError {
            switch error {
            case .statusCode(let statusCode, _, _):
                XCTAssertEqual(statusCode, 500, "Status code should be preserved in the error")
            default:
                XCTFail("Error should be of type .statusCode")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Invalid Response Tests
    
    func testInvalidResponseType() {
        // Given
        let successData = Data()
        let invalidResponse = URLResponse()
        
        // When/Then
        do {
            _ = try RequestValidation.validate(successData, invalidResponse)
            XCTFail("Validation should fail for non-HTTPURLResponse")
        } catch let error as APIError {
            XCTAssertEqual(error, .invalidResponse, "Should throw invalidResponse error")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyData() {
        // Given
        let emptyData = Data()
        let successResponse = HTTPURLResponse(
            url: URL(string: "https://example.com/api/test")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        // When/Then
        do {
            let validatedData = try RequestValidation.validate(emptyData, successResponse)
            XCTAssertEqual(validatedData, emptyData, "Empty data should be valid")
        } catch {
            XCTFail("Empty data with 200 status should be valid: \(error)")
        }
    }
    
    // MARK: - Complex Error Response Tests
    
    func testComplexErrorResponse() {
        // Given
        let complexErrorData = try! JSONSerialization.data(withJSONObject: [
            "error": true,
            "message": "Validation failed",
            "details": [
                "field1": ["Invalid format"],
                "field2": ["Required field missing"]
            ]
        ])
        let errorResponse = HTTPURLResponse(
            url: URL(string: "https://example.com/api/test")!,
            statusCode: 422,
            httpVersion: nil,
            headerFields: nil
        )!
        
        // When/Then
        do {
            _ = try RequestValidation.validate(complexErrorData, errorResponse)
            XCTFail("Validation should fail for unprocessable entity status")
        } catch let error as APIError {
            switch error {
            case .statusCode(let statusCode, let serverError as ServerError, _):
                XCTAssertEqual(statusCode, 422, "Status code should be preserved")
                XCTAssertNotNil(serverError.errorDescription, "Should have a detailed error description")
                XCTAssertTrue(serverError.errorDescription?.contains("field1") ?? false, "Should include field-specific errors")
            default:
                XCTFail("Error should be of type .statusCode with ServerError")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}

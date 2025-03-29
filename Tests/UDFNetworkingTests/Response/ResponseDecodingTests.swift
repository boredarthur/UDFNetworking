//
//  ResponseDecodingTests.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 14.03.2025.
//

import XCTest
@testable import UDFNetworking

final class ResponseDecodingTests: BaseTests {
    
    // MARK: - Test Models
    
    private struct TestModel: Codable, Equatable {
        let id: Int
        let name: String
    }
    
    private struct TestResponse: Codable, Equatable {
        let result: TestModel
    }
    
    private struct DateTestModel: Codable, Equatable {
        let id: Int
        let timestamp: Date
    }
    
    private struct SnakeCaseModel: Codable, Equatable {
        let userId: Int
        let firstName: String
        let lastName: String
        
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case firstName = "first_name"
            case lastName = "last_name"
        }
    }
    
    // MARK: - Basic Decoding Tests
    
    func testBasicDecoding() throws {
        // Given: JSON data for a simple model
        let jsonData = """
        {
            "id": 123,
            "name": "Test Model"
        }
        """.data(using: .utf8)!
        
        // When: Decoding with ResponseDecoding
        let model = try ResponseDecoding.decode(jsonData, as: TestModel.self)
        
        // Then: Should decode the model correctly
        XCTAssertEqual(model.id, 123)
        XCTAssertEqual(model.name, "Test Model")
    }
    
    func testDecodingWithDefaultDecoder() throws {
        // Given: JSON data with snake_case keys
        let jsonData = """
        {
            "user_id": 123,
            "first_name": "John",
            "last_name": "Doe"
        }
        """.data(using: .utf8)!
        
        // When: Using the default decoder (which should use convertFromSnakeCase)
        let model = try ResponseDecoding.decode(jsonData, as: SnakeCaseModel.self)
        
        // Then: Should decode with the default strategy
        XCTAssertEqual(model.userId, 123)
        XCTAssertEqual(model.firstName, "John")
        XCTAssertEqual(model.lastName, "Doe")
    }
    
    // MARK: - Unwrapping Tests
    
    func testDecodingWithUnwrap() throws {
        // Given: JSON data with a nested object
        let jsonData = """
        {
            "result": {
                "id": 789,
                "name": "Nested Model"
            }
        }
        """.data(using: .utf8)!
        
        // When: Decoding with unwrap
        let model = try ResponseDecoding.decode(jsonData, as: TestModel.self, unwrapBy: "result")
        
        // Then: Should unwrap and decode the model
        XCTAssertEqual(model.id, 789)
        XCTAssertEqual(model.name, "Nested Model")
    }
    
    func testDecodingWithUnwrapMissingKey() throws {
        // Given: JSON data without the specified unwrap key
        let jsonData = """
        {
            "data": {
                "id": 789,
                "name": "Nested Model"
            }
        }
        """.data(using: .utf8)!
        
        // When: Attempting to decode with an incorrect unwrap key
        // Then: It should fall back to direct decoding and throw an error
        // since "id" and "name" aren't at the top level
        XCTAssertThrowsError(try ResponseDecoding.decode(jsonData, as: TestModel.self, unwrapBy: "result"))
    }
    
    func testDecodingWithEmptyUnwrapKey() throws {
        // Given: JSON data that directly matches the model
        let jsonData = """
        {
            "id": 123,
            "name": "Direct Model"
        }
        """.data(using: .utf8)!
        
        // When: Decoding with an empty unwrap key
        let model = try ResponseDecoding.decode(jsonData, as: TestModel.self, unwrapBy: "")
        
        // Then: Should decode directly
        XCTAssertEqual(model.id, 123)
        XCTAssertEqual(model.name, "Direct Model")
    }
    
    // MARK: - Error Handling Tests
    
    func testDecodingInvalidJSON() {
        // Given: Invalid JSON data
        let invalidJsonData = "Not valid JSON".data(using: .utf8)!
        
        // When/Then: Attempting to decode should throw
        XCTAssertThrowsError(try ResponseDecoding.decode(invalidJsonData, as: TestModel.self)) { error in
            XCTAssertEqual(error as? APIError, APIError.invalidJSON)
        }
    }
    
    func testDecodingMismatchedTypes() {
        // Given: JSON with mismatched types
        let mismatchedData = """
        {
            "id": "not a number",
            "name": "Type Mismatch"
        }
        """.data(using: .utf8)!
        
        // When/Then: Attempting to decode should throw
        XCTAssertThrowsError(try ResponseDecoding.decode(mismatchedData, as: TestModel.self)) { error in
            XCTAssertEqual(error as? APIError, APIError.invalidJSON)
        }
    }
    
    func testDecodingMissingFields() {
        // Given: JSON with missing required fields
        let missingFieldsData = """
        {
            "name": "Missing ID Field"
        }
        """.data(using: .utf8)!
        
        // When/Then: Attempting to decode should throw
        XCTAssertThrowsError(try ResponseDecoding.decode(missingFieldsData, as: TestModel.self)) { error in
            XCTAssertEqual(error as? APIError, APIError.invalidJSON)
        }
    }
    
    // MARK: - Default Decoder Configuration Tests
    
    func testDefaultDecoderConfiguration() {
        // Test that the default decoder handles snake_case conversion correctly
        let snakeCaseJSON = """
        {
            "user_id": 123,
            "first_name": "John",
            "last_name": "Doe"
        }
        """.data(using: .utf8)!
        
        do {
            let model = try ResponseDecoding.decode(snakeCaseJSON, as: SnakeCaseModel.self)
            XCTAssertEqual(model.userId, 123)
            XCTAssertEqual(model.firstName, "John")
            XCTAssertEqual(model.lastName, "Doe")
        } catch {
            XCTFail("Default decoder should handle snake_case conversion: \(error)")
        }
        
        // Test that the default decoder handles ISO8601 dates correctly
        let dateJSON = """
        {
            "id": 456,
            "timestamp": "2025-03-14T12:30:45Z"
        }
        """.data(using: .utf8)!
        
        do {
            let model = try ResponseDecoding.decode(dateJSON.self, as: DateTestModel.self)
            XCTAssertEqual(model.id, 456)
            
            // Create an ISO8601 formatter to verify the date
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            
            // Format the decoded date back to a string and compare with the original
            let formattedDate = formatter.string(from: model.timestamp)
            XCTAssertEqual(formattedDate, "2025-03-14T12:30:45Z", "Date should be decoded correctly")
        } catch {
            XCTFail("Default decoder should handle ISO8601 dates: \(error)")
        }
    }
}

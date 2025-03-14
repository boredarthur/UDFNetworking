//
//  UnwrapContainerTests.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 14.03.2025.
//

import XCTest
@testable import UDFNetworking

final class UnwrapContainerTests: BaseTests {
    
    // MARK: - Test Models
    
    // Simple test model
    private struct TestModel: Codable, Equatable {
        let id: Int
        let name: String
    }
    
    // MARK: - UnwrapContainer Tests
    
    func testUnwrapWithSpecifiedKey() throws {
        // Given: JSON with a nested value under a specific key
        let json = ["data": ["id": 123, "name": "Test Model"]]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        
        // When: Using UnwrapContainer with a specified key
        let decoder = JSONDecoder()
        let unwrapKey = CodingUserInfoKey(rawValue: kUnwrapKey)!
        decoder.userInfo[unwrapKey] = "data"
        
        let unwrapped = try decoder.decode(UnwrapContainer<TestModel>.self, from: jsonData)
        
        // Then: Should extract the value from under the specified key
        XCTAssertEqual(unwrapped.value.id, 123)
        XCTAssertEqual(unwrapped.value.name, "Test Model")
    }
    
    func testUnwrapUsingFirstKey() throws {
        // Given: JSON with a single key (but not specifying which key to use)
        let json = ["result": ["id": 456, "name": "Auto Unwrapped"]]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        
        // When: Using UnwrapContainer without specifying a key
        let unwrapped = try JSONDecoder().decode(UnwrapContainer<TestModel>.self, from: jsonData)
        
        // Then: Should automatically use the first available key
        XCTAssertEqual(unwrapped.value.id, 456)
        XCTAssertEqual(unwrapped.value.name, "Auto Unwrapped")
    }
    
    func testUnwrapWithMultipleKeys() throws {
        // Given: JSON with multiple top-level keys
        let json = [
            "first": ["id": 111, "name": "First Model"],
            "second": ["id": 222, "name": "Second Model"]
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        
        // When: Using UnwrapContainer with a specific key
        let decoder = JSONDecoder()
        let unwrapKey = CodingUserInfoKey(rawValue: kUnwrapKey)!
        decoder.userInfo[unwrapKey] = "second"
        
        let unwrapped = try decoder.decode(UnwrapContainer<TestModel>.self, from: jsonData)
        
        // Then: Should extract the value from under the specified key
        XCTAssertEqual(unwrapped.value.id, 222)
        XCTAssertEqual(unwrapped.value.name, "Second Model")
    }
    
    func testUnwrapWithFirstKeyWhenMultipleExist() throws {
        // Given: JSON with multiple top-level keys but no specific key specified
        let json = [
            "first": ["id": 111, "name": "First Model"],
            "second": ["id": 222, "name": "Second Model"]
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        
        // When: Using UnwrapContainer without specifying a key
        let unwrapped = try JSONDecoder().decode(UnwrapContainer<TestModel>.self, from: jsonData)
        
        // Then: Should use the first key (which depends on dictionary ordering)
        // Note: Dictionary ordering isn't guaranteed, so we should check that it's one of the valid models
        let isFirstModel = unwrapped.value.id == 111 && unwrapped.value.name == "First Model"
        let isSecondModel = unwrapped.value.id == 222 && unwrapped.value.name == "Second Model"
        
        XCTAssertTrue(isFirstModel || isSecondModel, "Should unwrap one of the valid models")
    }
    
    func testUnwrapNestedArray() throws {
        // Given: JSON with a nested array
        let json = ["items": [
            ["id": 1, "name": "Item 1"],
            ["id": 2, "name": "Item 2"]
        ]]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        
        // When: Using UnwrapContainer with array type
        let decoder = JSONDecoder()
        let unwrapKey = CodingUserInfoKey(rawValue: kUnwrapKey)!
        decoder.userInfo[unwrapKey] = "items"
        
        let unwrapped = try decoder.decode(UnwrapContainer<[TestModel]>.self, from: jsonData)
        
        // Then: Should extract the array correctly
        XCTAssertEqual(unwrapped.value.count, 2)
        XCTAssertEqual(unwrapped.value[0].id, 1)
        XCTAssertEqual(unwrapped.value[0].name, "Item 1")
        XCTAssertEqual(unwrapped.value[1].id, 2)
        XCTAssertEqual(unwrapped.value[1].name, "Item 2")
    }
    
    func testUnwrapWithNonexistentKey() throws {
        // Given: JSON with keys that don't match the requested key
        let json = ["data": ["id": 123, "name": "Test Model"]]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        
        // When: Using UnwrapContainer with a nonexistent key
        let decoder = JSONDecoder()
        let unwrapKey = CodingUserInfoKey(rawValue: kUnwrapKey)!
        decoder.userInfo[unwrapKey] = "nonexistent"
        
        // Then: Should throw a decoding error
        XCTAssertThrowsError(try decoder.decode(UnwrapContainer<TestModel>.self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError, "Should throw a DecodingError")
        }
    }
    
    func testUnwrapFromEmptyContainer() throws {
        // Given: Empty JSON object
        let json: [String: Any] = [:]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        
        // When/Then: Should throw when trying to unwrap from an empty container
        XCTAssertThrowsError(try JSONDecoder().decode(UnwrapContainer<TestModel>.self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError, "Should throw a DecodingError")
        }
    }
    
    // MARK: - Testing the KeyedDecodingContainer Extensions
    
    func testDecodeSafelyExtension() throws {
        struct TestStruct: Decodable {
            let required: String
            let optional: String?
            let missing: Int?
            
            enum CodingKeys: String, CodingKey {
                case required, optional, missing
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                // Test the decode(_ key:) extension
                required = try container.decode(.required)
                
                // Test the decodeSafely extension
                optional = container.decodeSafely(.optional)
                missing = container.decodeSafely(.missing)
            }
        }
        
        // Given: JSON with some fields present and some missing
        let json = ["required": "Required Value", "optional": "Optional Value"]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        
        // When: Decoding using our extensions
        let result = try JSONDecoder().decode(TestStruct.self, from: jsonData)
        
        // Then: Should decode correctly using our extension methods
        XCTAssertEqual(result.required, "Required Value")
        XCTAssertEqual(result.optional, "Optional Value")
        XCTAssertNil(result.missing, "Missing field should be nil")
    }
}

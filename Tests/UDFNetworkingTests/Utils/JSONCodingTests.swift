//
//  JSONCodingTests.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 14.03.2025.
//

import XCTest
@testable import UDFNetworking

final class JSONCodingTests: BaseTests {
    
    // MARK: - Test Models
    
    private struct TestModel: Codable, Equatable {
        let id: Int
        let name: String
        let active: Bool
    }
    
    private struct SnakeCaseModel: Codable, Equatable {
        let userId: Int
        let firstName: String
        let lastName: String
    }
    
    private struct DateModel: Codable, Equatable {
        let id: Int
        let createdAt: Date
        let updatedAt: Date?
        
        enum CodingKeys: String, CodingKey {
            case id
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }
    
    // MARK: - Encoding Tests
    
    func testBasicEncoding() throws {
        // Given: A basic model to encode
        let model = TestModel(id: 123, name: "Test Model", active: true)
        
        // When: Encoding with the default encoder
        let data = try JSONCoding.encode(model)
        
        // Then: The data should be valid JSON
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["id"] as? Int, 123)
        XCTAssertEqual(json?["name"] as? String, "Test Model")
        XCTAssertEqual(json?["active"] as? Bool, true)
    }
    
    func testDateEncoding() throws {
        // Given: A model with Date properties
        let now = Date()
        let model = DateModel(id: 456, createdAt: now, updatedAt: nil)
        
        // When: Encoding with the default encoder (which should use ISO8601)
        let data = try JSONCoding.encode(model)
        
        // Then: The dates should be encoded in ISO8601 format
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["id"] as? Int, 456)
        
        // Verify the date is formatted as ISO8601
        let createdAt = json?["createdAt"] as? Double
        XCTAssertNotNil(createdAt)
        
        // Try to parse it back with an ISO8601 formatter
        let formatter = ISO8601DateFormatter()
        let parsedDate = formatter.date(from: Date(timeIntervalSinceReferenceDate: createdAt!).ISO8601Format())
        XCTAssertNotNil(parsedDate)
        
        // The updatedAt should be null
        XCTAssertNil(json?["updated_at"])
    }
    
    func testCustomEncoding() throws {
        // Given: A model and a custom encoder
        let model = TestModel(id: 789, name: "Custom Encoded", active: false)
        let customEncoder = JSONEncoder()
        customEncoder.outputFormatting = .prettyPrinted
        
        // When: Encoding with the custom encoder
        let data = try JSONCoding.encode(model, encoder: customEncoder)
        
        // Then: The data should be pretty-printed JSON
        let string = String(data: data, encoding: .utf8)
        XCTAssertTrue(string?.contains("  ") ?? false, "JSON should be pretty-printed")
        
        // And should contain the correct values
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        XCTAssertEqual(json?["id"] as? Int, 789)
    }
    
    func testEncodeToString() throws {
        // Given: A model
        let model = TestModel(id: 123, name: "String Encoded", active: true)
        
        // When: Encoding to a string
        let jsonString = try JSONCoding.encodeToString(model)
        
        // Then: The string should be valid JSON
        XCTAssertTrue(jsonString.contains("\"id\":123"))
        XCTAssertTrue(jsonString.contains("\"name\":\"String Encoded\""))
        XCTAssertTrue(jsonString.contains("\"active\":true"))
    }
    
    // MARK: - Decoding Tests
    
    func testBasicDecoding() throws {
        // Given: JSON data for a model
        let json = """
        {
            "id": 123,
            "name": "Test Model",
            "active": true
        }
        """.data(using: .utf8)!
        
        // When: Decoding with the default decoder
        let model = try JSONCoding.decode(json, as: TestModel.self)
        
        // Then: The model should be correctly decoded
        XCTAssertEqual(model.id, 123)
        XCTAssertEqual(model.name, "Test Model")
        XCTAssertEqual(model.active, true)
    }
    
    func testDateDecoding() throws {
        // Given: JSON data with ISO8601 date strings
        let json = """
        {
            "id": 456,
            "created_at": "2025-03-14T12:30:45Z",
            "updated_at": null
        }
        """.data(using: .utf8)!

        // When: Decoding with the default decoder
        let model = try JSONCoding.decode(json, as: DateModel.self)
        
        // Then: The dates should be correctly decoded
        XCTAssertEqual(model.id, 456)
        
        // Verify the date components
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: model.createdAt)
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 14)
        
        // The updatedAt should be nil
        XCTAssertNil(model.updatedAt)
    }
    
    func testCustomDecoding() throws {
        // Given: JSON data and a custom decoder
        let json = """
        {
            "id": 789,
            "name": "Custom Decoded",
            "active": false
        }
        """.data(using: .utf8)!
        
        let customDecoder = JSONDecoder()
        customDecoder.keyDecodingStrategy = .useDefaultKeys // Different from default
        
        // When: Decoding with the custom decoder
        let model = try JSONCoding.decode(json, as: TestModel.self, decoder: customDecoder)
        
        // Then: The model should be correctly decoded
        XCTAssertEqual(model.id, 789)
        XCTAssertEqual(model.name, "Custom Decoded")
        XCTAssertEqual(model.active, false)
    }
    
    func testDecodeFromString() throws {
        // Given: A JSON string
        let jsonString = """
        {
            "id": 123,
            "name": "String Decoded",
            "active": true
        }
        """
        
        // When: Decoding from a string
        let model = try JSONCoding.decode(jsonString, as: TestModel.self)
        
        // Then: The model should be correctly decoded
        XCTAssertEqual(model.id, 123)
        XCTAssertEqual(model.name, "String Decoded")
        XCTAssertEqual(model.active, true)
    }
    
    // MARK: - Error Tests
    
    func testInvalidJSONEncoding() {
        // Given: A type that can't be encoded to JSON
        class NonEncodable {}
        
        struct InvalidModel: Encodable {
            let value: NonEncodable = NonEncodable()
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                throw EncodingError.invalidValue(
                    value,
                    EncodingError.Context(
                        codingPath: [CodingKeys.value],
                        debugDescription: "Cannot encode NonEncodable"
                    )
                )
            }
            
            enum CodingKeys: String, CodingKey {
                case value
            }
        }
        
        // When/Then: Encoding should throw
        XCTAssertThrowsError(try JSONCoding.encode(InvalidModel()))
        XCTAssertThrowsError(try JSONCoding.encodeToString(InvalidModel()))
    }
    
    func testInvalidJSONDecoding() {
        // Given: Invalid JSON data
        let invalidJSON = "Not valid JSON".data(using: .utf8)!
        
        // When/Then: Decoding should throw
        XCTAssertThrowsError(try JSONCoding.decode(invalidJSON, as: TestModel.self))
        XCTAssertThrowsError(try JSONCoding.decode("Not valid JSON", as: TestModel.self))
    }
    
    // MARK: - Pretty Print Test
    
    func testPrettyPrint() {
        // Given: JSON data
        let model = TestModel(id: 123, name: "Pretty Printed", active: true)
        let data = try! JSONCoding.encode(model)
        
        // When: Pretty printing
        let prettyString = JSONCoding.prettyPrint(data)
        
        // Then: The string should be formatted with indentation and unquoted keys
        XCTAssertNotNil(prettyString)
        
        // Check for the unquoted key format
        XCTAssertTrue(prettyString?.contains("name:") ?? false, "Keys should be unquoted")
        XCTAssertTrue(prettyString?.contains("id:") ?? false, "Keys should be unquoted")
        XCTAssertTrue(prettyString?.contains("active:") ?? false, "Keys should be unquoted")
        
        // Check for the values
        XCTAssertTrue(prettyString?.contains("123") ?? false, "Pretty-printed JSON should contain the ID value")
        XCTAssertTrue(prettyString?.contains("Pretty Printed") ?? false, "Pretty-printed JSON should contain the name value")
        XCTAssertTrue(prettyString?.contains("true") ?? false, "Pretty-printed JSON should contain the active value")
    }
    
    func testPrettyPrintWithInvalidJSON() {
        // Given: Invalid JSON data
        let invalidData = "Not valid JSON".data(using: .utf8)!
        
        // When: Pretty printing
        let prettyString = JSONCoding.prettyPrint(invalidData)
        
        // Then: Should return nil
        XCTAssertNil(prettyString)
    }
}

//
//  APIConfigurationTests.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 06.03.2025.
//

import XCTest
@testable import UDFNetworking

final class APIConfigurationTests: BaseTests {
    
    // MARK: - Basic Configuration Tests
    
    func testBasicConfigurationProperties() {
        // Given
        let baseURL = URL(string: "https://api.example.com")!
        let cdnURL = URL(string: "https://cdn.example.com")!
        let mediaURL = URL(string: "https://media.example.com")!
        let timeoutInterval: TimeInterval = 42
        let headers = ["X-App-Version": "1.0.0", "Accept-Language": "en-US"]
        
        // When
        let config = APIConfiguration(
            baseURL: baseURL,
            cdnURL: cdnURL,
            mediaCDNURL: mediaURL,
            timeoutInterval: timeoutInterval,
            defaultHeaders: headers,
            logLevel: .debug
        )
        
        // Then
        XCTAssertEqual(config.baseURL, baseURL, "Base URL should match the provided value")
        XCTAssertEqual(config.cdnURL, cdnURL, "CDN URL should match the provided value")
        XCTAssertEqual(config.mediaCDNURL, mediaURL, "Media CDN URL should match the provided value")
        XCTAssertEqual(config.timeoutInterval, timeoutInterval, "Timeout interval should match the provided value")
        XCTAssertEqual(config.defaultHeaders, headers, "Default headers should match the provided values")
        XCTAssertEqual(config.logLevel, .debug, "Log level should match the provided value")
    }
    
    func testDefaultValues() {
        // Given
        let baseURL = URL(string: "https://api.example.com")!
        
        // When
        let config = APIConfiguration(baseURL: baseURL)
        
        // Then
        XCTAssertEqual(config.baseURL, baseURL, "Base URL should match the provided value")
        XCTAssertNil(config.cdnURL, "CDN URL should be nil by default")
        XCTAssertNil(config.mediaCDNURL, "Media CDN URL should be nil by default")
        XCTAssertEqual(config.timeoutInterval, 30, "Default timeout interval should be 30 seconds")
        XCTAssertEqual(config.defaultHeaders["Content-Type"], "application/json", "Default Content-Type header should be application/json")
        XCTAssertEqual(config.logLevel, .error, "Default log level should be .error")
    }
    
    // MARK: - Custom Properties Tests
    
    func testCustomPropertiesGetSet() {
        // Given
        let config = APIConfiguration(baseURL: URL(string: "https://api.example.com")!)
        
        // When: Set and get string value
        config.setValue("v1.2", forKey: "apiVersion")
        let retrievedVersion: String? = config.getValue(forKey: "apiVersion")
        
        // Then
        XCTAssertEqual(retrievedVersion, "v1.2", "Should retrieve the same string value that was set")
        
        // When: Set and get integer value
        config.setValue(42, forKey: "maxRetries")
        let retrievedInt: Int? = config.getValue(forKey: "maxRetries")
        
        // Then
        XCTAssertEqual(retrievedInt, 42, "Should retrieve the same integer value that was set")
        
        // When: Set and get boolean value
        config.setValue(true, forKey: "enableCaching")
        let retrievedBool: Bool? = config.getValue(forKey: "enableCaching")
        
        // Then
        XCTAssertEqual(retrievedBool, true, "Should retrieve the same boolean value that was set")
        
        // When: Get a non-existent key
        let nonExistentValue: String? = config.getValue(forKey: "nonExistentKey")
        
        // Then
        XCTAssertNil(nonExistentValue, "Should return nil for non-existent keys")
        
        // When: Override an existing value
        config.setValue("v2.0", forKey: "apiVersion")
        let updatedVersion: String? = config.getValue(forKey: "apiVersion")
        
        // Then
        XCTAssertEqual(updatedVersion, "v2.0", "Should update existing values")
    }
    
    func testCustomPropertiesWithDifferentTypes() {
        // Given
        let config = APIConfiguration(baseURL: URL(string: "https://api.example.com")!)
        
        // When: Set a string but retrieve as int
        config.setValue("not an int", forKey: "numberKey")
        let wrongTypeValue: Int? = config.getValue(forKey: "numberKey")
        
        // Then
        XCTAssertNil(wrongTypeValue, "Should return nil when trying to get a value with the wrong type")
        
        // When: Set a complex object
        let complexObject = ["key1": "value1", "key2": 42] as [String: Any]
        config.setValue(complexObject, forKey: "complexObject")
        let retrievedObject: [String: Any]? = config.getValue(forKey: "complexObject")
        
        // Then
        XCTAssertNotNil(retrievedObject, "Should be able to store and retrieve complex objects")
        XCTAssertEqual(retrievedObject?["key1"] as? String, "value1", "Complex object properties should be preserved")
    }
    
    // MARK: - Convenience Methods Tests
    
    func testWithAuthorizationMethod() {
        // Given
        let config = APIConfiguration(baseURL: URL(string: "https://api.example.com")!)
        
        // When
        let configWithAuth = config.withAuthorization(token: "Bearer", defaultToken: "test-token")
        
        // Then
        let retrievedTokenType: String? = configWithAuth.getValue(forKey: "token")
        let retrievedToken: String? = configWithAuth.getValue(forKey: "defaultToken")
        
        XCTAssertEqual(retrievedTokenType, "Bearer", "Should store token in custom properties")
        XCTAssertEqual(retrievedToken, "test-token", "Should store defaultToken in custom properties")
        XCTAssertTrue(config === configWithAuth, "withAuthorization should return the same instance for chaining")
    }
    
    // MARK: - API Configuration Integration Tests
    
    func testGlobalAPIConfiguration() {
        // Given
        let testConfig = APIConfiguration(
            baseURL: URL(string: "https://test.example.com")!,
            logLevel: .verbose
        )
        
        // When
        API.configure(with: testConfig)
        
        // Then
        XCTAssertTrue(API.isConfigured(), "API should be configured after calling configure()")
        
        // Instead of identity check, we verify the properties match
        XCTAssertEqual(API.configuration?.baseURL, testConfig.baseURL, "API.configuration should have the same baseURL")
        XCTAssertEqual(API.configuration?.logLevel, testConfig.logLevel, "API.configuration should have the same logLevel")
        
        // When
        API.reset()
        
        // Then
        XCTAssertFalse(API.isConfigured(), "API.isConfigured() should return false after reset")
        XCTAssertNil(API.configuration, "API.configuration should be nil after reset")
    }
    
    func testLoggingLevelConfigure() {
        // Given
        let config = APIConfiguration(
            baseURL: URL(string: "https://api.example.com")!,
            logLevel: .verbose
        )
        
        // When
        API.configure(with: config)
        
        // Then
        // Note: Since logLevel is internal, we can only test the public API
        // This test demonstrates the configuration works but doesn't directly verify the internal state
        
        // When
        API.setLoggingLevel(.debug)
        
        // Then
        // We can verify the config was updated if we have access to it
        XCTAssertEqual(config.logLevel, .debug, "logLevel should be updated via API.setLoggingLevel()")
    }
}

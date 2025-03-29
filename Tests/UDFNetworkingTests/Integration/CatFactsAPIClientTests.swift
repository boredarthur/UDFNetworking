//
//  CatFactsAPIClientTests.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 14.03.2025.
//

import XCTest
@testable import UDFNetworking

final class CatFactsAPIClientTests: BaseTests {
    
    // MARK: - Cat Facts Models
    
    private struct CatFact: Decodable, Equatable {
        let fact: String
        let length: Int
    }
    
    private struct CatFactsList: Decodable {
        let data: [CatFact]
        let perPage: Int
        let currentPage: Int
        let lastPage: Int
        let total: Int
        let from: Int?
        let to: Int?
        
        enum CodingKeys: String, CodingKey {
            case data
            case perPage = "per_page"
            case currentPage = "current_page"
            case lastPage = "last_page"
            case total
            case from
            case to
        }
    }
    
    private struct CatBreed: Decodable, Equatable {
        let breed: String
        let country: String
        let origin: String
        let coat: String
        let pattern: String
    }
    
    private struct CatBreedsList: Decodable {
        let data: [CatBreed]
        let perPage: Int
        let currentPage: Int
        let lastPage: Int
        let total: Int
        let from: Int?
        let to: Int?
        
        enum CodingKeys: String, CodingKey {
            case data
            case perPage = "per_page"
            case currentPage = "current_page"
            case lastPage = "last_page"
            case total
            case from
            case to
        }
    }
    
    // MARK: - Cat Facts API Client
    
    private enum CatFactsAPI: BaseAPIClientProtocol {
        enum Endpoints: APIEndpoint {
            case facts
            case fact
            case breeds
            case nonExistent
            
            var rawValue: String {
                switch self {
                case .facts:
                    return "/facts"
                case .fact:
                    return "/fact"
                case .breeds:
                    return "/breeds"
                case .nonExistent:
                    return "/non-existent-endpoint"
                }
            }
        }
    }
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        
        // Configure API with Cat Fact Ninja base URL
        let catFactsConfig = APIConfiguration(
            baseURL: URL(string: "https://catfact.ninja")!,
            timeoutInterval: 30,
            defaultHeaders: ["Content-Type": "application/json"],
            logLevel: .debug
        )
        
        API.configure(with: catFactsConfig)
    }
    
    override func tearDown() {
        API.reset()
        super.tearDown()
    }
    
    // MARK: - Helper Method
    
    private func skipIfCatFactsAPIUnavailable() async -> Bool {
        do {
            // Try a simple request to check if the API is responding
            let _: CatFact = try await CatFactsAPI.fetchResource(
                endpoint: CatFactsAPI.Endpoints.fact
            )
            return false // API is available, don't skip
        } catch {
            // If we get an error
            print("⚠️ Cat Facts API appears to be unavailable: \(error)")
            print("⚠️ Skipping this test to avoid false failures.")
            return true // API is unavailable, skip test
        }
    }
    
    // MARK: - Integration Tests
    
    func testFetchRandomCatFact() async throws {
        // Skip if the API is unavailable
        if await skipIfCatFactsAPIUnavailable() {
            return
        }
        
        // Fetch a random cat fact
        let fact: CatFact = try await CatFactsAPI.fetchResource(
            endpoint: CatFactsAPI.Endpoints.fact
        )
        
        // Verify the fact has text
        XCTAssertFalse(fact.fact.isEmpty, "Cat fact should have text")
        
        // Verify the length is reasonable
        XCTAssertGreaterThan(fact.length, 0, "Fact length should be positive")
        XCTAssertEqual(fact.fact.count, fact.length, "Fact length should match text length")
    }
    
    func testFetchRandomCatFactWithMaxLength() async throws {
        // Skip if the API is unavailable
        if await skipIfCatFactsAPIUnavailable() {
            return
        }
        
        // Fetch a random cat fact with maximum length
        let maxLength = 50
        let fact: CatFact = try await CatFactsAPI.fetchResource(
            endpoint: CatFactsAPI.Endpoints.fact,
            parameters: {
                URLQueryItem(name: "max_length", value: String(maxLength))
            }
        )
        
        // Verify the fact has text
        XCTAssertFalse(fact.fact.isEmpty, "Cat fact should have text")
        
        // Verify the length is within the specified maximum
        XCTAssertLessThanOrEqual(fact.length, maxLength, "Fact length should be <= max_length")
    }
    
    func testFetchCatFactsList() async throws {
        // Skip if the API is unavailable
        if await skipIfCatFactsAPIUnavailable() {
            return
        }
        
        // Fetch a list of cat facts
        let factsList: CatFactsList = try await CatFactsAPI.fetchResource(endpoint: .facts)
        
        // Verify we got some facts
        XCTAssertFalse(factsList.data.isEmpty, "Should have fetched at least one cat fact")
        
        // Verify pagination info
        XCTAssertGreaterThan(factsList.total, 0, "Total facts should be positive")
        XCTAssertEqual(factsList.currentPage, 1, "Default page should be 1")
        
        // Verify the facts have the expected structure
        for fact in factsList.data {
            XCTAssertFalse(fact.fact.isEmpty, "Cat fact should have text")
            XCTAssertGreaterThan(fact.length, 0, "Fact length should be positive")
        }
    }
    
    func testFetchCatFactsWithPagination() async throws {
        // Skip if the API is unavailable
        if await skipIfCatFactsAPIUnavailable() {
            return
        }
        
        // Fetch page 2 with 5 facts per page
        let factsList: CatFactsList = try await CatFactsAPI.fetchResource(
            endpoint: CatFactsAPI.Endpoints.facts,
            parameters: {
                URLQueryItem(name: "page", value: "2")
                URLQueryItem(name: "limit", value: "5")
            }
        )
        
        // Verify pagination parameters were applied
        XCTAssertEqual(factsList.currentPage, 2, "Current page should be 2")
        XCTAssertEqual(factsList.perPage, 5, "Per page should be 5")
        XCTAssertLessThanOrEqual(factsList.data.count, 5, "Should have at most 5 facts")
    }
    
    func testFetchCatBreeds() async throws {
        // Skip if the API is unavailable
        if await skipIfCatFactsAPIUnavailable() {
            return
        }
        
        // Fetch cat breeds
        let breedsList: CatBreedsList = try await CatFactsAPI.fetchResource(endpoint: .breeds)
        
        // Verify we got some breeds
        XCTAssertFalse(breedsList.data.isEmpty, "Should have fetched at least one cat breed")
        
        // Verify the breeds have the expected structure
        for breed in breedsList.data {
            XCTAssertFalse(breed.breed.isEmpty, "Breed should have a name")
            XCTAssertFalse(breed.country.isEmpty, "Breed should have a country")
        }
    }
    
    func testErrorHandling() async {
        // Skip if the API is unavailable
        if await skipIfCatFactsAPIUnavailable() {
            return
        }
        
        // Try to access a non-existent endpoint
        do {
            struct EmptyResponse: Decodable {}
            
            let _: EmptyResponse = try await CatFactsAPI.fetchResource(
                endpoint: .nonExistent
            )
            XCTFail("Expected an error for invalid endpoint")
        } catch let error as APIError {
            // We should get an error (likely 404 Not Found)
            if case .statusCode(let code, _, _) = error {
                XCTAssertEqual(code, 404, "Expected 404 status code for invalid endpoint")
            } else {
                // If not a status code error, it might be another kind of API error
                print("Got error type: \(error)")
            }
        } catch {
            XCTFail("Expected an APIError but got: \(error)")
        }
    }
}

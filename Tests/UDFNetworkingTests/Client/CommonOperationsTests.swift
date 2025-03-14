//
//  CommonOperationsTests.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 14.03.2025.
//

import XCTest
@testable import UDFNetworking

final class CommonOperationsTests: BaseTests {
    
    // MARK: - Test Models
    
    private struct User: Codable, Equatable {
        let id: Int
        let name: String
        let email: String
        let username: String?
        let website: String?
        let phone: String?
        
        // Required for comparing with JSONPlaceholder responses
        static func == (lhs: User, rhs: User) -> Bool {
            return lhs.id == rhs.id && 
            lhs.name == rhs.name && 
            lhs.email == rhs.email
        }
    }
    
    private struct Post: Codable, Equatable {
        let id: Int
        let title: String
        let body: String
        let userId: Int
    }
    
    private struct NewPost: Codable {
        let title: String
        let body: String
        let userId: Int
    }
    
    private struct NewUser: Codable {
        let name: String
        let email: String
        let username: String
    }
    
    // MARK: - Test API Client
    
    private enum JSONPlaceholderAPI: BaseAPIClientProtocol {
        // Endpoints with associated values
        enum Endpoints: APIEndpoint {
            case users
            case user(id: Int)
            case posts
            case post(id: Int)
            case userPosts(userId: Int)
            
            var rawValue: String {
                switch self {
                case .users:
                    return "/users"
                case .user(let id):
                    return "/users/\(id)"
                case .posts:
                    return "/posts"
                case .post(let id):
                    return "/posts/\(id)"
                case .userPosts(let userId):
                    return "/users/\(userId)/posts"
                }
            }
        }
    }
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        
        // Configure API with JSONPlaceholder
        let jsonPlaceholderConfig = APIConfiguration(
            baseURL: URL(string: "https://jsonplaceholder.typicode.com")!,
            timeoutInterval: 10,
            defaultHeaders: ["Content-Type": "application/json"],
            logLevel: .debug
        )
        
        API.configure(with: jsonPlaceholderConfig)
    }
    
    override func tearDown() {
        // Reset to default configuration
        API.reset()
        super.tearDown()
    }
    
    // MARK: - Fetch Resource Tests
    
    func testFetchResource() async throws {
        // When: Fetching a user by ID
        let user: User = try await JSONPlaceholderAPI.fetchResource(
            endpoint: JSONPlaceholderAPI.Endpoints.user(id: 1)
        )
        
        // Then: Should return the expected user
        XCTAssertEqual(user.id, 1)
        XCTAssertFalse(user.name.isEmpty, "Name should not be empty")
        XCTAssertFalse(user.email.isEmpty, "Email should not be empty")
    }
    
    func testFetchResourceWithParameters() async throws {
        // When: Fetching posts with specific ID as parameter
        let posts: [Post] = try await JSONPlaceholderAPI.fetchCollection(
            endpoint: JSONPlaceholderAPI.Endpoints.posts,
            unwrapBy: "",
            parameters: {
                URLQueryItem(name: "id", value: "1")
            }
        )
        
        // Then: Should return the post with ID 1
        XCTAssertEqual(posts.count, 1, "Should return exactly one post")
        XCTAssertEqual(posts[0].id, 1)
        XCTAssertFalse(posts[0].title.isEmpty, "Title should not be empty")
        XCTAssertFalse(posts[0].body.isEmpty, "Body should not be empty")
    }
    
    // MARK: - Fetch Collection Tests
    
    func testFetchCollection() async throws {
        // When: Fetching all users
        let users: [User] = try await JSONPlaceholderAPI.fetchCollection(
            endpoint: JSONPlaceholderAPI.Endpoints.users,
            unwrapBy: ""
        )
        
        // Then: Should return a non-empty collection
        XCTAssertFalse(users.isEmpty, "Should return at least one user")
        XCTAssertEqual(users.count, 10, "JSONPlaceholder should return 10 users")
        
        // Verify first user
        XCTAssertEqual(users[0].id, 1)
        XCTAssertFalse(users[0].name.isEmpty, "Name should not be empty")
    }
    
    func testFetchCollectionWithParameters() async throws {
        // When: Fetching posts by user ID
        let posts: [Post] = try await JSONPlaceholderAPI.fetchCollection(
            endpoint: JSONPlaceholderAPI.Endpoints.posts,
            unwrapBy: "",
            parameters: {
                URLQueryItem(name: "userId", value: "1")
            }
        )
        
        // Then: Should return posts for user 1
        XCTAssertFalse(posts.isEmpty, "Should return at least one post")
        
        // Verify all posts belong to user 1
        for post in posts {
            XCTAssertEqual(post.userId, 1, "All posts should belong to user 1")
        }
    }
    
    // MARK: - Create Resource Tests
    
    func testCreateResource() async throws {
        // When: Creating a new post
        let post: Post = try await JSONPlaceholderAPI.createResource(
            endpoint: JSONPlaceholderAPI.Endpoints.posts,
            parameters: {
                URLQueryItem(name: "title", value: "Test Title")
                URLQueryItem(name: "body", value: "Test Body")
                URLQueryItem(name: "userId", value: "1")
            }
        )
        
        // Then: Should return the created post with a new ID
        // JSONPlaceholder typically assigns ID 101 for new posts
        XCTAssertGreaterThan(post.id, 0, "Created post should have an ID")
        XCTAssertEqual(post.title, "Test Title")
        XCTAssertEqual(post.body, "Test Body")
        XCTAssertEqual(post.userId, 1)
    }
    
    // MARK: - Update Resource Tests
    
    func testUpdateResource() async throws {
        // When: Updating a post
        let updatedPost: Post = try await JSONPlaceholderAPI.updateResource(
            endpoint: JSONPlaceholderAPI.Endpoints.post(id: 1),
            parameters: {
                URLQueryItem(name: "title", value: "Updated Title")
                URLQueryItem(name: "body", value: "Updated Body")
                URLQueryItem(name: "userId", value: "1")
            }
        )
        
        // Then: Should return the updated post
        XCTAssertEqual(updatedPost.id, 1)
        XCTAssertEqual(updatedPost.title, "Updated Title")
        XCTAssertEqual(updatedPost.body, "Updated Body")
    }
    
    // MARK: - Patch Resource Tests
    
    func testPatchResource() async throws {
        // When: Patching a post (only updating the title)
        let patchedPost: Post = try await JSONPlaceholderAPI.patchResource(
            endpoint: JSONPlaceholderAPI.Endpoints.post(id: 1),
            parameters: {
                URLQueryItem(name: "title", value: "Patched Title")
            }
        )
        
        // Then: Should return the patched post
        XCTAssertEqual(patchedPost.id, 1)
        XCTAssertEqual(patchedPost.title, "Patched Title")
        // Body should still be present but we didn't specify it in the patch
        XCTAssertFalse(patchedPost.body.isEmpty)
    }
    
    // MARK: - Delete Resource Tests
    
    func testDeleteResource() async throws {
        // When: Deleting a post
        try await JSONPlaceholderAPI.deleteResource(
            endpoint: JSONPlaceholderAPI.Endpoints.post(id: 1)
        )
        
        // Then: The operation should complete without throwing an error
        // JSONPlaceholder returns 200 for successful deletes
    }
    
    func testDeleteResourceWithParameters() async throws {
        // When: Deleting a post with a parameter
        try await JSONPlaceholderAPI.deleteResource(
            endpoint: JSONPlaceholderAPI.Endpoints.post(id: 1),
            parameters: {
                URLQueryItem(name: "permanent", value: "true")
            }
        )
        
        // Then: The operation should complete without throwing an error
        // JSONPlaceholder doesn't actually use the parameters for DELETE, but this tests
        // that our API client correctly handles DELETE requests with parameters
    }
    
    // MARK: - Error Tests
    
    func testErrorHandling() async {
        // When: Trying to fetch a non-existent resource
        do {
            let _: User = try await JSONPlaceholderAPI.fetchResource(
                endpoint: JSONPlaceholderAPI.Endpoints.user(id: 999999)
            )
            XCTFail("Expected an error for non-existent resource")
        } catch let error as APIError {
            // Then: Should throw a status code error
            switch error {
            case .statusCode(let code, _, _):
                XCTAssertEqual(code, 404, "Should throw 404 for non-existent resource")
            default:
                XCTFail("Expected .statusCode error but got: \(error)")
            }
        } catch {
            XCTFail("Expected APIError but got: \(error)")
        }
    }
    
    // MARK: - Additional test for empty response with 204 status
    
    func testHandlingEmptyResponse() async throws {
        // When: Making a request that returns empty response with 204 status
        // This simulates an endpoint that returns no content but succeeds
        // JSONPlaceholder doesn't have a true 204 endpoint, so we'll skip verifying results
        // and just test that our code handles the scenario appropriately by not throwing
        
        // Get a small post first to ensure it exists
        let _: Post = try await JSONPlaceholderAPI.fetchResource(
            endpoint: JSONPlaceholderAPI.Endpoints.post(id: 1)
        )
        
        // Then try to delete it - JSONPlaceholder simulates this but doesn't actually delete
        try await JSONPlaceholderAPI.deleteResource(
            endpoint: JSONPlaceholderAPI.Endpoints.post(id: 1)
        )
        
        // Test passes if no exception is thrown
    }
}

//
//  BaseAPIClientProtocolTests.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 10.03.2025.
//

import XCTest
import Combine
@testable import UDFNetworking

final class BaseAPIClientProtocolTests: BaseTests {
    
    // Post model matching JSONPlaceholder API
    private struct Post: Codable, Equatable {
        let id: Int?
        let title: String?
        let body: String?
        let userId: Int?
        
        private enum CodingKeys: String, CodingKey {
            case id
            case title
            case body
            case userId
        }
        
        // Add a custom init to handle partial or missing data
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Make all properties optional and provide default values
            id = try? container.decodeIfPresent(Int.self, forKey: .id)
            title = try? container.decodeIfPresent(String.self, forKey: .title)
            body = try? container.decodeIfPresent(String.self, forKey: .body)
            userId = try? container.decodeIfPresent(Int.self, forKey: .userId)
        }
        
        // Optional manual encoding if needed
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try? container.encodeIfPresent(id, forKey: .id)
            try? container.encodeIfPresent(title, forKey: .title)
            try? container.encodeIfPresent(body, forKey: .body)
            try? container.encodeIfPresent(userId, forKey: .userId)
        }
    }
    
    // Comment model for nested resources
    private struct Comment: Codable, Equatable {
        let id: Int
        let postId: Int
        let name: String
        let email: String
        let body: String
    }
    
    // API Client for JSONPlaceholder
    private enum JSONPlaceholderAPIClient: BaseAPIClientProtocol {
        enum Endpoints: APIEndpoint {
            case posts
            case comments
            case post(id: Int)
            
            var rawValue: String {
                switch self {
                case .posts:
                    return "/posts"
                case .comments:
                    return "/comments"
                case .post(let id):
                    return "/posts/\(id)"
                }
            }
        }
        
        // Fetch all posts
        static func fetchPosts() async throws -> [Post] {
            return try await fetchCollection(
                endpoint: Endpoints.posts,
                unwrapBy: ""
            )
        }
        
        // Fetch a specific post
        static func fetchPost(id: Int) async throws -> Post {
            return try await fetchResource(
                endpoint: Endpoints.post(id: id),
                unwrapBy: ""
            )
        }
        
        // Fetch posts by user
        static func fetchPostsByUser(userId: Int) async throws -> [Post] {
            return try await fetchCollection(
                endpoint: Endpoints.posts,
                unwrapBy: "",
                parameters: {
                    URLQueryItem(name: "userId", value: String(userId))
                }
            )
        }
        
        // Fetch comments for a specific post
        static func fetchPostComments(postId: Int) async throws -> [Comment] {
            return try await fetchCollection(
                endpoint: Endpoints.comments,
                unwrapBy: "",
                parameters: {
                    URLQueryItem(name: "postId", value: String(postId))
                }
            )
        }
        
        // Create a new post
        static func createPost(title: String, body: String, userId: Int) async throws -> Post {
            return try await createResource(
                endpoint: Endpoints.posts,
                unwrapBy: "",
                parameters: {
                    URLQueryItem(name: "title", value: title)
                    URLQueryItem(name: "body", value: body)
                    URLQueryItem(name: "userId", value: String(userId))
                }
            )
        }
    }
    
    override func setUp() {
        super.setUp()
        
        // Configure with JSONPlaceholder API
        let config = APIConfiguration(
            baseURL: URL(string: "https://jsonplaceholder.typicode.com")!,
            timeoutInterval: 10,
            defaultHeaders: ["Content-Type": "application/json"],
            logLevel: .debug
        )
        
        API.configure(with: config)
    }
    
    // Test fetching all posts
    func testFetchAllPosts() async {
        do {
            let posts = try await JSONPlaceholderAPIClient.fetchPosts()
            
            XCTAssertTrue(posts.count > 0, "Should fetch multiple posts")
            XCTAssertNotNil(posts.first?.title, "Posts should have titles")
        } catch {
            XCTFail("Fetching posts failed: \(error)")
        }
    }
    
    // Test fetching a specific post
    func testFetchSpecificPost() async {
        do {
            let post = try await JSONPlaceholderAPIClient.fetchPost(id: 1)
            
            XCTAssertEqual(post.id, 1, "Should fetch post with correct ID")
            XCTAssertNotNil(post.title, "Post should have a title")
        } catch {
            XCTFail("Fetching specific post failed: \(error)")
        }
    }
    
    // Test filtering posts by user
    func testFetchPostsByUser() async {
        do {
            let posts = try await JSONPlaceholderAPIClient.fetchPostsByUser(userId: 1)
            
            XCTAssertTrue(posts.count > 0, "Should fetch posts for specific user")
            XCTAssertTrue(posts.allSatisfy { $0.userId == 1 }, "All posts should be from the specified user")
        } catch {
            XCTFail("Fetching posts by user failed: \(error)")
        }
    }
    
    // Test fetching comments for a post
    func testFetchPostComments() async {
        do {
            let comments = try await JSONPlaceholderAPIClient.fetchPostComments(postId: 1)
            
            XCTAssertTrue(comments.count > 0, "Should fetch comments for the post")
            XCTAssertTrue(comments.allSatisfy { $0.postId == 1 }, "All comments should be for the specified post")
        } catch {
            XCTFail("Fetching post comments failed: \(error)")
        }
    }
    
    // Test creating a new post
    func testCreatePost() async {
        do {
            let newPost = try await JSONPlaceholderAPIClient.createPost(
                title: "Test Title", 
                body: "Test Body", 
                userId: 1
            )
            
            XCTAssertNotNil(newPost.id, "Created post should have an ID")
            XCTAssertEqual(newPost.title, "Test Title", "Post title should match")
            XCTAssertEqual(newPost.body, "Test Body", "Post body should match")
        } catch {
            XCTFail("Creating post failed: \(error)")
        }
    }
    
    // Test error handling for non-existent resource
    func testErrorHandling() async {
        do {
            _ = try await JSONPlaceholderAPIClient.fetchPost(id: 999)
            XCTFail("Fetching non-existent post should fail")
        } catch let error as APIError {
            switch error {
            case .statusCode(let statusCode, _, _):
                XCTAssertEqual(statusCode, 404, "Should receive 404 for non-existent post")
            default:
                XCTFail("Should throw status code error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}

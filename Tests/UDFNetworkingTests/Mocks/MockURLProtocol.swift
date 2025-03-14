//
//  MockURLProtocol.swift
//  UDFNetworking
//
//  Created by Arthur Zavolovych on 06.03.2025.
//

import Foundation

/// A custom URLProtocol implementation for mocking network responses in tests
class MockURLProtocol: URLProtocol {
    /// A handler that processes requests and returns mock responses
    /// Usage: Set this handler in your test setup to respond with mock data
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    /// Determines whether this protocol can handle the given request
    /// Always returns true to intercept all requests during testing
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    /// Returns the canonical version of the request
    /// We return the original request since we're not modifying it
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    /// Starts loading the request
    /// This is where we intercept the request and provide a mock response
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            // If no handler is set, respond with a 404 error
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorResourceUnavailable, userInfo: nil)
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        do {
            // Process the request through the handler
            let (response, data) = try handler(request)
            
            // Send the response to the client
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            // If the handler throws an error, fail the request
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    /// Stops loading the request
    /// No action needed here for our mock implementation
    override func stopLoading() {}
    
    // MARK: - Helper Methods
    
    /// Creates a mock HTTP response with the given status code and data
    /// - Parameters:
    ///   - request: The original URLRequest
    ///   - statusCode: HTTP status code to return
    ///   - data: Response data
    ///   - headers: Optional response headers
    /// - Returns: A tuple with the response and data
    static func mockHTTPResponse(
        for request: URLRequest,
        statusCode: Int,
        data: Data,
        headers: [String: String] = ["Content-Type": "application/json"]
    ) -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(
            url: request.url ?? URL(string: "https://mock.example.com")!,
            statusCode: statusCode,
            httpVersion: "HTTP/2",
            headerFields: headers
        )!
        
        return (response, data)
    }
    
    /// Sets up a success response with JSON data
    /// - Parameters:
    ///   - json: Dictionary to return as JSON
    ///   - statusCode: HTTP status code (default 200)
    static func respondWithJSON(_ json: [String: Any], statusCode: Int = 200) {
        requestHandler = { request in
            let data = try JSONSerialization.data(withJSONObject: json)
            return mockHTTPResponse(for: request, statusCode: statusCode, data: data)
        }
    }
    
    /// Sets up an error response
    /// - Parameters:
    ///   - statusCode: HTTP error status code
    ///   - errorMessage: Optional error message to include in response
    static func respondWithError(statusCode: Int, errorMessage: String? = nil) {
        requestHandler = { request in
            var errorJSON: [String: Any] = ["error": true]
            if let message = errorMessage {
                errorJSON["message"] = message
            }
            let data = try JSONSerialization.data(withJSONObject: errorJSON)
            return mockHTTPResponse(for: request, statusCode: statusCode, data: data)
        }
    }
    
    /// Sets up a network error (not HTTP error)
    /// - Parameter code: URLError code to use
    static func respondWithNetworkError(_ code: URLError.Code = .notConnectedToInternet) {
        requestHandler = { _ in
            throw URLError(code)
        }
    }
    
    /// Registers this protocol for use with URLSession
    /// - Returns: A URLSessionConfiguration with this protocol registered
    static func registerMockProtocol() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return config
    }
}

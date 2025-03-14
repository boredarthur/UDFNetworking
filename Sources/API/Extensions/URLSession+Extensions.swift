//
//  URLSession+Extensions.swift
//  
//
//  Created by Arthur Zavolovych on 05.03.2025.
//

import Foundation
import Combine

public extension URLSession {
    /// Create a publisher that validates data before emitting.
    /// - Parameter request: The URL request.
    /// - Returns: A publisher that emits validated data.
    func validateDataTaskPublisher(request: URLRequest) -> AnyPublisher<Data, Error> {
        dataTaskPublisher(for: request)
            .tryMap { try RequestValidation.validate($0.data, $0.response) }
            .eraseToAnyPublisher()
    }
    
    /// Download a file from a URL.
    /// - Parameters:
    ///   - url: The source URL.
    ///   - destinationFileURL: The destination file URL.
    /// - Returns: The URL response.
    /// - Throws: An error if the download fails.
    @discardableResult
    func downloadTask(for url: URL, destinationFileURL: URL) async throws -> URLResponse {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.downloadTask(with: URLRequest(url: url)) { url, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let response = response else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                
                guard let url = url else {
                    continuation.resume(throwing: URLError(.badURL))
                    return
                }
                
                do {
                    let fileManager = FileManager.default
                    if fileManager.fileExists(atPath: destinationFileURL.path) {
                        try fileManager.removeItem(atPath: destinationFileURL.path)
                    }
                    
                    try fileManager.moveItem(atPath: url.path, toPath: destinationFileURL.path)
                    continuation.resume(returning: response)
                } catch {
                    continuation.resume(throwing: URLError(.cannotCreateFile))
                }
            }
            
            task.resume()
        }
    }
    
    /// Check if a URL has expired.
    /// - Parameters:
    ///   - url: The URL to check.
    ///   - completion: A completion handler called with the result.
    func hasUrlExpired(url: URL, _ completion: @escaping (Bool) -> Void) {
        let task = dataTask(with: url) { _, response, error in
            if let _ = error {
                completion(true)
            } else if let httpResponse = response as? HTTPURLResponse {
                if (200 ... 299).contains(httpResponse.statusCode) {
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
        
        task.resume()
    }
}

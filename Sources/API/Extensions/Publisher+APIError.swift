//
//  Publisher+APIError.swift
//  
//
//  Created by Arthur Zavolovych on 05.03.2025.
//

import Foundation
import Combine

public extension Publisher {
    /// Map errors to APIError.
    /// - Returns: A publisher that emits APIError for all errors.
    func mapErrorToAPIError() -> Publishers.MapError<Self, APIError> {
        return mapError { error -> APIError in
            switch error {
            case let apiError as APIError:
                return apiError
                
            case let urlError as URLError:
                return .networkError(urlError)
                
            case let nsError as NSError:
                return .statusCode(nsError.code, nsError, nsError.userInfo)
                
            default:
                return .custom(error.localizedDescription)
            }
        }
    }
}

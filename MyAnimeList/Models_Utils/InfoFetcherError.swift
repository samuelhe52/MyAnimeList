//
//  InfoFetcherError.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation

enum InfoFetcherError: LocalizedError {
    case unableToMatchMetadata(String)
    case mediaTypeMismatch((expected: String, actual: String))
    
    var errorDescription: String? {
        switch self {
        case .unableToMatchMetadata(let name):
            return "Could not find a corresponding item in tmdb for \(name)"
        case .mediaTypeMismatch(let (expected, actual)):
            return "MediaType mismatch: expected \(expected), actual \(actual)"
        }
    }
}

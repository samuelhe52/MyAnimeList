//
//  InfoFetcher.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation
import TMDb

actor InfoFetcher: Sendable {
    let tmdbClient: TMDbClient
    var language: Language
    
    init(language: Language = .english) {
        self.tmdbClient = .init(apiKey: "***REMOVED***")
        self.language = language
    }
    
    func searchAll(name: String) async throws -> [Media] {
        let results = try await tmdbClient.search.searchAll(query: name, page: 1, language: language.rawValue)
        return results.results
    }

    func searchMovies(name: String) async throws -> [MovieListItem] {
        let results = try await tmdbClient.search.searchMovies(query: name, page: 1, language: language.rawValue)
        return results.results
    }

    func searchTVSeries(name: String) async throws -> [TVSeriesListItem] {
        let results = try await tmdbClient.search.searchTVSeries(query: name, page: 1, language: language.rawValue)
        return results.results
    }
    
    static let shared = InfoFetcher()
}

enum Language: String, CaseIterable {
    case english = "en"
    case chinese = "zh"
    case japanese = "ja"
}

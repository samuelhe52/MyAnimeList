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
    
    func changeLanguage(_ language: Language) {
        self.language = language
    }
    
    func searchAll(name: String) async throws -> [Media] {
        let results = try await tmdbClient.search.searchAll(query: name, page: 1, language: language.rawValue)
        return results.results.filter {
            switch $0 {
            // 16 is the genre id for animation
            case .movie(let movie): movie.genreIDs.contains(16)
            case .tvSeries(let series): series.genreIDs.contains(16)
            case .person(_): false
            }
        }
    }

    func searchMovies(name: String) async throws -> [MovieListItem] {
        let results = try await tmdbClient.search.searchMovies(query: name, page: 1, language: language.rawValue)
        // 16 is the genre id for animation
        return results.results.filter { $0.genreIDs.contains(16) }
    }

    func searchTVSeries(name: String) async throws -> [TVSeriesListItem] {
        let results = try await tmdbClient.search.searchTVSeries(query: name, page: 1, language: language.rawValue)
        // 16 is the genre id for animation
        return results.results.filter { $0.genreIDs.contains(16) }
    }
    
    static let shared = InfoFetcher()
}

enum Language: String, CaseIterable, CustomStringConvertible {
    case english = "en"
    case chinese = "zh"
    case japanese = "ja"
    
    var description: String {
        switch self {
        case .chinese: return "Chinese"
        case .english: return "English"
        case .japanese: return "Japanese"
        }
    }
}

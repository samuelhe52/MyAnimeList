//
//  InfoFetcher.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation
import TMDb

actor InfoFetcher {
    let tmdbClient: TMDbClient
    
    init(language: Language = .english) {
        self.tmdbClient = .init(apiKey: "***REMOVED***")
    }
    
    func fetchMovie(_ tmdbID: Int, language: Language) async throws -> Movie {
        try await tmdbClient.movies.details(forMovie: tmdbID, language: language.rawValue)
    }
    
    func fetchTVSeries(_ tmdbID: Int, language: Language) async throws -> TVSeries {
        try await tmdbClient.tvSeries.details(forTVSeries: tmdbID, language: language.rawValue)
    }
    
    func searchAll(name: String, language: Language) async throws -> [Media] {
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

    func searchMovies(name: String, language: Language) async throws -> [MovieListItem] {
        let results = try await tmdbClient.search.searchMovies(query: name, page: 1, language: language.rawValue)
        // 16 is the genre id for animation
        return results.results.filter { $0.genreIDs.contains(16) }
    }

    func searchTVSeries(name: String, language: Language) async throws -> [TVSeriesListItem] {
        let results = try await tmdbClient.search.searchTVSeries(query: name, page: 1, language: language.rawValue)
        // 16 is the genre id for animation
        return results.results.filter { $0.genreIDs.contains(16) }
    }
    
    func fetchInfoFromTMDB(entryType: MediaTypeMetadata, tmdbID: Int, language: Language) async throws -> BasicInfo {
        switch entryType {
        case .tvSeason(let seasonNumber, let parentSeriesID):
            return try await tvSeasonInfo(seasonNumber: seasonNumber, parentSeriesID: parentSeriesID)
        case .movie:
            return try await movieInfo()
        case .tvSeries:
            return try await tvSeriesInfo()
        }
        
        func tvSeasonInfo(seasonNumber: Int, parentSeriesID: Int) async throws -> BasicInfo {
            let season = try await tmdbClient.tvSeasons.details(forSeason: seasonNumber,
                                                                inTVSeries: parentSeriesID,
                                                                language: language.rawValue)
            let parentSeries = try await tmdbClient.tvSeries.details(forTVSeries: parentSeriesID,
                                                                     language: language.rawValue)
            var basicInfo = try await season.basicInfo(client: tmdbClient)
            // Use the parent series' backdrop image and homepage for the season.
            basicInfo.backdropURL = try await parentSeries.backdropURL(client: tmdbClient)
            basicInfo.linkToDetails = parentSeries.homepageURL
            return basicInfo
        }
        
        func movieInfo() async throws -> BasicInfo {
            let movie = try await tmdbClient.movies.details(forMovie: tmdbID, language: language.rawValue)
            return try await movie.basicInfo(client: tmdbClient)
        }
        
        func tvSeriesInfo() async throws -> BasicInfo {
            let season = try await tmdbClient.tvSeries.details(forTVSeries: tmdbID, language: language.rawValue)
            return try await season.basicInfo(client: tmdbClient)
        }
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

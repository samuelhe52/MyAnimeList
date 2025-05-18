//
//  InfoFetcher.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation
import TMDb
import Combine

/// A class for fetching media infos from TMDb.
/// - Important: Setup proper monitoring mechanism for the `.tmdbAPIKey` key change in `UserDefaults` as this class does not provide a built-in monitor-and-refresh feature.
final class InfoFetcher: Sendable {
    let tmdbClient: TMDbClient
    
    convenience init() {
        let bypassGFW = UserDefaults.standard.bool(forKey: .tmdbAPIGFWBypass)
        self.init(bypassGFW: bypassGFW)
    }
    
    init(bypassGFW: Bool) {
        let key = UserDefaults.standard.string(forKey: .tmdbAPIKey)
        if bypassGFW {
            self.tmdbClient = .init(apiKey: key ?? "",
                                    httpClient: RedirectingHTTPClient.bypassGFWForTMDbAPI)
        } else {
            self.tmdbClient = .init(apiKey: key ?? "")
        }
    }
    
    func movie(_ tmdbID: Int, language: Language) async throws -> Movie {
        try await tmdbClient.movies.details(forMovie: tmdbID, language: language.rawValue)
    }
    
    func tvSeries(_ tmdbID: Int, language: Language) async throws -> TVSeries {
        try await tmdbClient.tvSeries.details(forTVSeries: tmdbID, language: language.rawValue)
    }
    
    func tvSeason(_ parentSeriesID: Int, seasonNumber: Int, language: Language) async throws -> TVSeason {
        try await tmdbClient.tvSeasons.details(forSeason: seasonNumber,
                                               inTVSeries: parentSeriesID,
                                               language: language.rawValue)
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
    
    func fetchInfoFromTMDB(entryType: AnimeType, tmdbID: Int, language: Language) async throws -> BasicInfo {
        switch entryType {
        case .season(let seasonNumber, let parentSeriesID):
            return try await tvSeasonInfo(seasonNumber: seasonNumber, parentSeriesID: parentSeriesID, language: language)
        case .movie:
            return try await movieInfo(tmdbID: tmdbID, language: language)
        case .series:
            return try await tvSeriesInfo(tmdbID: tmdbID, language: language)
        }
    }
    
    func tvSeasonInfo(seasonNumber: Int, parentSeriesID: Int, language: Language) async throws -> BasicInfo {
        let season = try await tmdbClient.tvSeasons.details(forSeason: seasonNumber,
                                                            inTVSeries: parentSeriesID,
                                                            language: language.rawValue)
        let parentSeries = try await tmdbClient.tvSeries.details(forTVSeries: parentSeriesID,
                                                                 language: language.rawValue)
        let backdropURL = try await parentSeries.backdropURL(client: tmdbClient)
        let linkToDetails = parentSeries.linkToDetails
        
        // Use the parent series' backdrop image and homepage for the season.
        let basicInfo = try await season.basicInfo(client: tmdbClient,
                                                   backdropURL: backdropURL,
                                                   linkToDetails: linkToDetails,
                                                   parentSeriesID: parentSeriesID)
        return basicInfo
    }
    
    func movieInfo(tmdbID: Int, language: Language) async throws -> BasicInfo {
        let movie = try await tmdbClient.movies.details(forMovie: tmdbID, language: language.rawValue)
        return try await movie.basicInfo(client: tmdbClient)
    }
    
    func tvSeriesInfo(tmdbID: Int, language: Language) async throws -> BasicInfo {
        let season = try await tmdbClient.tvSeries.details(forTVSeries: tmdbID, language: language.rawValue)
        return try await season.basicInfo(client: tmdbClient)
    }
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

extension RedirectingHTTPClient {
    static let bypassGFWForTMDbAPI: Self = .init(fromHost: "api.themoviedb.org", toHost: "api.tmdb.org")
}

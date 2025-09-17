//
//  InfoFetcher.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation
import TMDb
import DataProvider
import Combine
import SwiftUI

/// A class for fetching media infos from TMDb.
/// - Important: Setup proper monitoring mechanism for the `.tmdbAPIKey` key change in `UserDefaults` as this class does not provide a built-in monitor-and-refresh feature.
final class InfoFetcher: Sendable {
    let tmdbClient: TMDbClient
    
    init(apiKey: String? = nil) {
        let key = apiKey ?? TMDbAPIKeyStorage().key
        self.tmdbClient = .init(apiKey: key ?? "",
                                httpClient: RedirectingHTTPClient.relayServer)
    }
    
    init(client: TMDbClient) {
        self.tmdbClient = client
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
    
    func postersForMovie(for tmdbID: Int, idealWidth: Int = .max) async throws -> [ImageURLWithMetadata] {
        return try await tmdbClient.posterURLs(forMovie: tmdbID, idealWidth: idealWidth)
    }

    func backdropsForMovie(for tmdbID: Int, idealWidth: Int = .max) async throws -> [ImageURLWithMetadata] {
        return try await tmdbClient.backdropURLs(forMovie: tmdbID, idealWidth: idealWidth)
    }

    func logosForMovie(for tmdbID: Int, idealWidth: Int = .max) async throws -> [ImageURLWithMetadata] {
        return try await tmdbClient.logoURLs(forMovie: tmdbID, idealWidth: idealWidth)
    }

    func postersForSeries(seriesID tmdbID: Int, idealWidth: Int = .max) async throws -> [ImageURLWithMetadata] {
        return try await tmdbClient.posterURLs(forTVSeries: tmdbID, idealWidth: idealWidth)
    }

    func backdropsForSeries(for tmdbID: Int, idealWidth: Int = .max) async throws -> [ImageURLWithMetadata] {
        return try await tmdbClient.backdropURLs(forTVSeries: tmdbID, idealWidth: idealWidth)
    }

    func logosForSeries(for tmdbID: Int, idealWidth: Int = .max) async throws -> [ImageURLWithMetadata] {
        return try await tmdbClient.logoURLs(forTVSeries: tmdbID, idealWidth: idealWidth)
    }
    
    func postersForSeason(forSeason seasonNumber: Int,
                          inParentSeries parentSeriesID: Int,
                          idealWidth: Int = .max) async throws -> [ImageURLWithMetadata] {
        return try await tmdbClient.posterURLs(forSeason: seasonNumber, inTVSeries: parentSeriesID, idealWidth: idealWidth)
    }
}

enum Language: String, CaseIterable, CustomLocalizedStringResourceConvertible {
    case english = "en"
    case chinese = "zh"
    case japanese = "ja"
    
    static var current: Language {
        if let languageCodeID = Locale.current.language.languageCode?.identifier {
            return Language(rawValue: languageCodeID) ?? .english
        } else {
            return .english
        }
    }
    
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .chinese: return "Chinese"
        case .english: return "English"
        case .japanese: return "Japanese"
        }
    }
}

extension RedirectingHTTPClient {
    static let relayServer: Self = .init(fromHost: "api.themoviedb.org", toHost: "tmdb-api.konakona52.com")
}

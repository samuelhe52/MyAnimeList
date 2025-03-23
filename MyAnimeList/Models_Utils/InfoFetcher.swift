//
//  InfoFetcher.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation
import TMDb

class InfoFetcher {
    var tmdbClient: TMDbClient = .init(apiKey: "***REMOVED***")
    var language: Language = .japanese
    
    func search(name: String) async throws -> [Media] {
        let results = try await tmdbClient.search.searchAll(query: name, page: 1, language: language.rawValue)
        return results.results
    }
    
    /// Generate a type-agnostic `BasicMediaInfo` instance for a given `AnimeEntry`.
    func basicInfo(for entry: AnimeEntry) async throws -> BasicMediaInfo {
        switch entry.mediaType {
        case .tvSeries:
            let details = try await fetchTVSeriesInfo(entry: entry)
            let (posterURL, backdropURL) = try await fetchFullImageURLs(entryId: details.id, mediaType: entry.mediaType)
            return .init(name: details.name,
                         overview: details.overview,
                         posterURL: posterURL,
                         backdropURL: backdropURL,
                         tmdbId: details.id,
                         linkToDetails: details.homepageURL,
                         mediaType: .tvSeries)
        case .movie:
            let details = try await fetchMovieInfo(entry: entry)
            let (posterURL, backdropURL) = try await fetchFullImageURLs(entryId: details.id, mediaType: entry.mediaType)
            return .init(name: details.title,
                         overview: details.overview,
                         posterURL: posterURL,
                         backdropURL: backdropURL,
                         tmdbId: details.id,
                         linkToDetails: details.homepageURL,
                         mediaType: .tvSeries)
        }
    }
    
    func fetchTVSeriesInfo(entry: AnimeEntry) async throws -> TVSeries {
        if let tmdbId = entry.tmdbId {
            switch entry.mediaType {
            case .tvSeries:
                return try await tmdbClient.tvSeries.details(forTVSeries: tmdbId,
                                                                    language: language.rawValue)
            default: throw InfoFetcherError.mediaTypeMismatch(("TV Series", entry.mediaType.description))
            }
        } else {
            guard let searchResult = try await search(name: entry.name).first else {
                throw InfoFetcherError.unableToMatchMetadata(entry.name)
            }
            switch searchResult {
            case .tvSeries(let tvSeries):
                return try await tmdbClient.tvSeries.details(forTVSeries: tvSeries.id,
                                                             language: language.rawValue)
            case .movie: throw InfoFetcherError.mediaTypeMismatch(("TV Series", "Movie"))
            case .person: throw InfoFetcherError.mediaTypeMismatch(("TV Series", "Person"))
            }
        }
    }
    
    func fetchMovieInfo(entry: AnimeEntry) async throws -> Movie {
        if let tmdbId = entry.tmdbId {
            switch entry.mediaType {
            case .movie:
                return try await tmdbClient.movies.details(forMovie: tmdbId,
                                                                    language: language.rawValue)
            default: throw InfoFetcherError.mediaTypeMismatch(("Movies", entry.mediaType.description))
            }
        } else {
            guard let searchResult = try await search(name: entry.name).first else {
                throw InfoFetcherError.unableToMatchMetadata(entry.name)
            }
            switch searchResult {
            case .movie(let movie):
                return try await tmdbClient.movies.details(forMovie: movie.id,
                                                             language: language.rawValue)
            case .tvSeries: throw InfoFetcherError.mediaTypeMismatch(("Movies", "TV Series"))
            case .person: throw InfoFetcherError.mediaTypeMismatch(("Movies", "Person"))
            }
        }
    }
    
    // We use the original poster -- japanese version.
    /// Fetches full poster and backdrop urls for a given entry.
    func fetchFullImageURLs(entryId: Int, mediaType: AnimeEntry.MediaType) async throws -> (poster: URL?, backdrop: URL?) {
        var posterPath: URL? = nil
        var backdropPath: URL? = nil
        
        switch mediaType {
        case .tvSeries:
            posterPath = try await tmdbClient.tvSeries.details(forTVSeries: entryId, language: "ja").posterPath
            backdropPath = try await tmdbClient.tvSeries.details(forTVSeries: entryId, language: "ja").backdropPath
        case .movie:
            posterPath = try await tmdbClient.movies.details(forMovie: entryId, language: "ja").posterPath
            backdropPath = try await tmdbClient.movies.details(forMovie: entryId, language: "ja").backdropPath
        }
        
        let configurationService = tmdbClient.configurations
        let apiConfiguration = try await configurationService.apiConfiguration()
        let imagesConfiguration = apiConfiguration.images
        
        let posterURL = imagesConfiguration.posterURL(for: posterPath)
        let backdropURL = imagesConfiguration.backdropURL(for: backdropPath)
        return (posterURL, backdropURL)
    }
}

enum Language: String, CaseIterable {
    case english = "en"
    case chinese = "zh"
    case japanese = "ja"
}

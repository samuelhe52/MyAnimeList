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
    var language: Language = .chinese
    
    func search(name: String) async throws -> [Media] {
        let results = try await tmdbClient.search.searchAll(query: name, page: 1, language: language.rawValue)
        return results.results
    }
    
    func basicInfo(for item: AnimeItem) async throws -> BasicMediaInfo {
        switch item.mediaType {
        case .tvSeries:
            let details = try await fetchTVSeriesInfo(item: item)
            let posterURL = try await fetchFullImageURL(itemId: details.id, mediaType: item.mediaType)
            return .init(name: details.name,
                         overview: details.overview,
                         posterURL: posterURL,
                         tmdbId: details.id,
                         linkToDetails: details.homepageURL,
                         mediaType: .tvSeries)
        case .movie:
            let details = try await fetchMovieInfo(item: item)
            let posterURL = try await fetchFullImageURL(itemId: details.id, mediaType: item.mediaType)
            return .init(name: details.title,
                         overview: details.overview,
                         posterURL: posterURL,
                         tmdbId: details.id,
                         linkToDetails: details.homepageURL,
                         mediaType: .tvSeries)
        }
    }
    
    func fetchTVSeriesInfo(item: AnimeItem) async throws -> TVSeries {
        if let tmdbId = item.tmdbId {
            switch item.mediaType {
            case .tvSeries:
                return try await tmdbClient.tvSeries.details(forTVSeries: tmdbId,
                                                                    language: language.rawValue)
            default: throw InfoFetcherError.mediaTypeMismatch(("TV Series", item.mediaType.description))
            }
        } else {
            guard let searchResult = try await search(name: item.name).first else {
                throw InfoFetcherError.unableToMatchMetadata(item.name)
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
    
    func fetchMovieInfo(item: AnimeItem) async throws -> Movie {
        if let tmdbId = item.tmdbId {
            switch item.mediaType {
            case .movie:
                return try await tmdbClient.movies.details(forMovie: tmdbId,
                                                                    language: language.rawValue)
            default: throw InfoFetcherError.mediaTypeMismatch(("Movies", item.mediaType.description))
            }
        } else {
            guard let searchResult = try await search(name: item.name).first else {
                throw InfoFetcherError.unableToMatchMetadata(item.name)
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
    func fetchFullImageURL(itemId: Int, mediaType: AnimeItem.MediaType) async throws -> URL? {
        var posterPath: URL? = nil
        switch mediaType {
        case .tvSeries:
            posterPath = try await tmdbClient.tvSeries.details(forTVSeries: itemId, language: "ja").posterPath
        case .movie:
            posterPath = try await tmdbClient.movies.details(forMovie: itemId, language: "ja").posterPath
        }
        
        let configurationService = tmdbClient.configurations
        let apiConfiguration = try await configurationService.apiConfiguration()
        let imagesConfiguration = apiConfiguration.images
        return imagesConfiguration.posterURL(for: posterPath)
    }
}

enum Language: String, CaseIterable {
    case english = "en"
    case chinese = "zh"
    case japanese = "ja"
}

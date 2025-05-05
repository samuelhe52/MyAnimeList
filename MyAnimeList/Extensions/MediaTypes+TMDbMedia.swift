//
//  MediaTypes+TMDbMedia.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/29.
//

import Foundation
import TMDb

extension Array where Element == ImageMetadata {
    var filterAndSortByBestQuality: [ImageMetadata] {
        self.filter { ($0.voteCount ?? 0) > 0 &&
            ($0.voteAverage ?? 0) > 0 &&
            $0.languageCode == Language.japanese.rawValue }
            .sorted { $0.height > $1.height }
    }
    
    var bestQuality: ImageMetadata? {
        filterAndSortByBestQuality.first
    }
}

extension Movie {
    /// Returns the basic information for the movie.
    ///
    /// - Parameters:
    ///   - client: The TMDb client used to fetch image configuration.
    /// - Returns: A `BasicInfo` struct containing metadata about the movie.
    func basicInfo(client: TMDbClient) async throws -> BasicInfo {
        let posterURL = try await posterURL(client: client)
        let backdropURL = try await backdropURL(client: client)
        let logoURL = try await logoURL(client: client)
        
        return BasicInfo(
            name: title,
            overview: overview,
            posterURL: posterURL,
            backdropURL: backdropURL,
            logoURL: logoURL,
            tmdbID: id,
            onAirDate: releaseDate,
            linkToDetails: homepageURL,
            typeMetadata: .movie
        )
    }
    
    func posterURLs(client: TMDb.TMDbClient) async throws -> [URL] {
        let collection = try await client.movies.images(forMovie: id)
        return await client.posters(from: collection)
    }
    
    func backdropURLs(client: TMDb.TMDbClient) async throws -> [URL] {
        let collection = try await client.movies.images(forMovie: id)
        return await client.backdrops(from: collection)
    }
    
    func logoURLs(client: TMDb.TMDbClient) async throws -> [URL] {
        let collection = try await client.movies.images(forMovie: id)
        return await client.logos(from: collection)
    }

    func backdropURL(client: TMDb.TMDbClient) async throws -> URL? {
        let imageResources = try await client.movies.images(forMovie: id)
        let bestQualityBackdropPath = imageResources.backdrops.bestQuality?.filePath
        return try await client.imagesConfiguration.backdropURL(for: bestQualityBackdropPath)
    }
    
    func posterURL(client: TMDb.TMDbClient) async throws -> URL? {
        let imageResources = try await client.movies.images(forMovie: id)
        let bestQualityBackdropPath = imageResources.posters.bestQuality?.filePath
        return try await client.imagesConfiguration.posterURL(for: bestQualityBackdropPath)
    }
    
    func logoURL(client: TMDb.TMDbClient) async throws -> URL? {
        let imageResources = try await client.movies.images(forMovie: id)
        let bestQualityBackdropPath = imageResources.logos.bestQuality?.filePath
        return try await client.imagesConfiguration.logoURL(for: bestQualityBackdropPath)
    }
    
    var name: String { title }
    var onAirDate: Date? { releaseDate }
    var linkToDetails: URL? { homepageURL }
}

extension TVSeries {
    /// Returns the basic information for the TV series.
    ///
    /// - Parameters:
    ///   - client: The TMDb client used to fetch image configuration.
    /// - Returns: A `BasicInfo` struct containing metadata about the TV series.
    func basicInfo(client: TMDbClient) async throws -> BasicInfo {
        let posterURL = try await posterURL(client: client)
        let backdropURL = try await backdropURL(client: client)
        let logoURL = try await logoURL(client: client)

        return BasicInfo(
            name: name,
            overview: overview,
            posterURL: posterURL,
            backdropURL: backdropURL,
            logoURL: logoURL,
            tmdbID: id,
            onAirDate: firstAirDate,
            linkToDetails: homepageURL,
            typeMetadata: .tvSeries
        )
    }
    
    func posterURL(client: TMDbClient) async throws -> URL? {
        let imageResources = try await client.tvSeries.images(forTVSeries: id)
        let bestQualityBackdropPath = imageResources.posters.bestQuality?.filePath
        return try await client.imagesConfiguration.posterURL(for: bestQualityBackdropPath)
    }
    
    func backdropURL(client: TMDbClient) async throws -> URL? {
        let imageResources = try await client.tvSeries.images(forTVSeries: id)
        let bestQualityBackdropPath = imageResources.backdrops.bestQuality?.filePath
        return try await client.imagesConfiguration.backdropURL(for: bestQualityBackdropPath)
    }
    
    func logoURL(client: TMDbClient) async throws -> URL? {
        let imageResources = try await client.tvSeries.images(forTVSeries: id)
        let bestQualityBackdropPath = imageResources.logos.bestQuality?.filePath
        return try await client.imagesConfiguration.logoURL(for: bestQualityBackdropPath)
    }
    
    func posterURLs(client: TMDbClient) async throws -> [URL] {
        let collection = try await client.movies.images(forMovie: id)
        return await client.posters(from: collection)
    }

    func backdropURLs(client: TMDbClient) async throws -> [URL] {
        let collection = try await client.movies.images(forMovie: id)
        return await client.backdrops(from: collection)
    }

    func logoURLs(client: TMDbClient) async throws -> [URL] {
        let collection = try await client.movies.images(forMovie: id)
        return await client.logos(from: collection)
    }
    
    var onAirDate: Date? { firstAirDate }
    var linkToDetails: URL? { homepageURL }
}

extension TVSeason {
    ///
    /// Returns the basic information for the TV season.
    ///
    /// - Parameters:
    ///   - client: The TMDb client used to fetch image configuration.
    /// - Returns: A `BasicInfo` struct containing metadata about the TV season.
    ///
    /// - Warning: The `posterURL`, `backdropURL` and `logoURL` are nil unless explicitly provided.
    func basicInfo(client: TMDbClient,
                   backdropURL: URL? = nil,
                   logoURL: URL? = nil,
                   linkToDetails: URL? = nil,
                   parentSeriesID: Int) async throws -> BasicInfo {
        let seasonPosterPath = try await client.tvSeasons
            .images(forSeason: seasonNumber, inTVSeries: parentSeriesID)
            .posters.bestQuality?.filePath
        var seasonPoster: URL?
        if let seasonPosterPath {
            seasonPoster = try await client.imagesConfiguration.posterURL(for: seasonPosterPath)
        } else {
            seasonPoster = try await client.imagesConfiguration.posterURL(for: posterPath)
        }
        return BasicInfo(
            name: name,
            overview: overview,
            posterURL: seasonPoster,
            backdropURL: backdropURL,
            logoURL: logoURL,
            tmdbID: id,
            onAirDate: airDate,
            linkToDetails: linkToDetails,
            typeMetadata: .tvSeason(seasonNumber: seasonNumber, parentSeriesID: parentSeriesID)
        )
    }
    
    func posterURL(client: TMDbClient) async throws -> URL? {
        return try await client.imagesConfiguration.posterURL(for: posterPath)
    }
    
    func backdropURL(client: TMDbClient) async throws -> URL? {
        throw ImageResourceError.noResourceDirectlyFromTVSeason
    }
    
    func logoURL(client: TMDb.TMDbClient) async throws -> URL? {
        throw ImageResourceError.noResourceDirectlyFromTVSeason
    }
    
    var onAirDate: Date? { airDate }
    var linkToDetails: URL? { nil }
}

enum ImageResourceError: Error {
    case noResourceDirectlyFromTVSeason
}

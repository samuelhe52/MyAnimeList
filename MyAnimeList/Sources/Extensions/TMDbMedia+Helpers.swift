//
//  TMDbMedia+Helpers.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/29.
//

import Foundation
import TMDb

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
            type: .movie
        )
    }
    
    /// Gets URLs for all poster images associated with the movie.
    ///
    /// - Parameter client: The TMDb client used for image configuration.
    /// - Returns: Array of URLs for poster images.
    func posterURLs(client: TMDb.TMDbClient) async throws -> [URL] {
        let collection = try await client.movies.images(forMovie: id)
        return await client.posters(from: collection)
    }
    
    /// Gets URLs for all backdrop images associated with the movie.
    ///
    /// - Parameter client: The TMDb client used for image configuration.
    /// - Returns: Array of URLs for backdrop images.
    func backdropURLs(client: TMDb.TMDbClient) async throws -> [URL] {
        let collection = try await client.movies.images(forMovie: id)
        return await client.backdrops(from: collection)
    }
    
    /// Gets URLs for all logo images associated with the movie.
    ///
    /// - Parameter client: The TMDb client used for image configuration.
    /// - Returns: Array of URLs for logo images.
    func logoURLs(client: TMDb.TMDbClient) async throws -> [URL] {
        let collection = try await client.movies.images(forMovie: id)
        return await client.logos(from: collection)
    }

    /// Gets URL for the primary backdrop image.
    ///
    /// - Parameter client: The TMDb client used for image configuration.
    func backdropURL(client: TMDb.TMDbClient) async throws -> URL? {
        return try await client.imagesConfiguration.backdropURL(for: backdropPath)
    }
    
    /// Gets URL for the best quality poster image.
    ///
    /// - Parameter client: The TMDb client used for image configuration.
    func posterURL(client: TMDb.TMDbClient) async throws -> URL? {
        return try await client.imagesConfiguration.posterURL(for: posterPath)
    }
    
    /// Gets URL for the primary logo image.
    ///
    /// - Parameter client: The TMDb client used for image configuration.
    func logoURL(client: TMDb.TMDbClient) async throws -> URL? {
        let imageResources = try await client.movies.images(forMovie: id)
        let logoPath = imageResources.logos.first?.filePath
        return try await client.imagesConfiguration.logoURL(for: logoPath)
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
            type: .series
        )
    }
    
    /// Gets URL for the best quality poster image.
    ///
    /// - Parameter client: The TMDb client used for image configuration.
    func posterURL(client: TMDbClient) async throws -> URL? {
        return try await client.imagesConfiguration.posterURL(for: posterPath)
    }
    
    /// Gets URL for the primary backdrop image.
    ///
    /// - Parameter client: The TMDb client used for image configuration.
    func backdropURL(client: TMDbClient) async throws -> URL? {
        return try await client.imagesConfiguration.backdropURL(for: backdropPath)
    }
    
    /// Gets URL for the primary logo image.
    ///
    /// - Parameter client: The TMDb client used for image configuration.
    func logoURL(client: TMDbClient) async throws -> URL? {
        let imageResources = try await client.tvSeries.images(forTVSeries: id)
        let logoPath = imageResources.logos.first?.filePath
        return try await client.imagesConfiguration.logoURL(for: logoPath)
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
    ///   - backdropURL: A backdrop URL that the returned `BasicInfo` uses. Default to nil since seasons don't have their own backdrops.
    ///   - logoURL: A logo URL that the returned `BasicInfo` uses. Default to nil since seasons don't have their own logos.
    ///   - linkToDetails: A homepage URL for this season. Default to nil since seasons don't have their own homepages.
    ///   - parentSeriesID: This season's parent series' TMDB ID.
    /// - Returns: A `BasicInfo` struct containing metadata about the TV season.
    func basicInfo(client: TMDbClient,
                   backdropURL: URL? = nil,
                   logoURL: URL? = nil,
                   linkToDetails: URL? = nil,
                   parentSeriesID: Int) async throws -> BasicInfo {
        let seasonPoster: URL? = try await client.imagesConfiguration.posterURL(for: posterPath)
        return BasicInfo(
            name: name,
            overview: overview,
            posterURL: seasonPoster,
            backdropURL: backdropURL,
            logoURL: logoURL,
            tmdbID: id,
            onAirDate: airDate,
            linkToDetails: linkToDetails,
            type: .season(seasonNumber: seasonNumber, parentSeriesID: parentSeriesID)
        )
    }
    
    /// Gets URL for the season's poster image.
    ///
    /// - Parameters:
    ///   - parentSeriesID: The ID of the parent TV series.
    ///   - client: The TMDb client used for image configuration.
    func posterURL(parentSeriesID: Int, client: TMDbClient) async throws -> URL? {
        return try await client.imagesConfiguration.posterURL(for: posterPath)
    }
    
    var onAirDate: Date? { airDate }
    var linkToDetails: URL? { nil }
}

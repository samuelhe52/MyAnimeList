//
//  TMDbMedia+Helpers.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/29.
//

import Foundation
import TMDb
import os

fileprivate let logger = Logger(subsystem: .bundleIdentifier, category: "TMDbMediaMetadataFetching")

extension Movie {
    /// Returns the basic information for the movie.
    ///
    /// - Parameters:
    ///   - client: The TMDb client used to fetch image configuration.
    /// - Returns: A `BasicInfo` struct containing metadata about the movie.
    func basicInfo(client: TMDbClient) async throws -> BasicInfo {
        logger.debug("Fetching basic info for movie \(self.id)")
        let posterURL = try await posterURL(client: client)
        let backdropURL = try await backdropURL(client: client)
        let logoURL = try await logoURL(client: client)
        
        logger.info("Successfully fetched basic info for movie \(self.id)")
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
    
    /// Gets URL for the backdrop image.
    ///
    /// - Parameter client: The TMDb client used for image configuration.
    func backdropURL(client: TMDb.TMDbClient, idealWidth: Int = .max) async throws -> URL? {
        let url = try await client.imagesConfiguration.backdropURL(for: backdropPath, idealWidth: idealWidth)
        return url
    }
    
    /// Gets URL for the poster image.
    ///
    /// - Parameter client: The TMDb client used for image configuration.
    func posterURL(client: TMDb.TMDbClient, idealWidth: Int = .max) async throws -> URL? {
        let url = try await client.imagesConfiguration.posterURL(for: posterPath, idealWidth: idealWidth)
        return url
    }
    
    /// Gets URL for the logo image.
    ///
    /// - Parameter client: The TMDb client used for image configuration.
    func logoURL(client: TMDb.TMDbClient, idealWidth: Int = .max) async throws -> URL? {
        let imageResources = try await client.movies.images(forMovie: id)
        let logoPath = imageResources.logos.first?.filePath
        let url = try await client.imagesConfiguration.logoURL(for: logoPath, idealWidth: idealWidth)
        return url
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
        logger.debug("Fetching basic info for TV series \(self.id)")
        let posterURL = try await posterURL(client: client)
        let backdropURL = try await backdropURL(client: client)
        let logoURL = try await logoURL(client: client)

        logger.info("Successfully fetched basic info for TV series \(self.id)")
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
    
    /// Gets URL for the poster image.
    ///
    /// - Parameter client: The TMDb client used for image configuration.
    func posterURL(client: TMDbClient) async throws -> URL? {
        return try await client.imagesConfiguration.posterURL(for: posterPath)
    }
    
    /// Gets URL for the backdrop image.
    ///
    /// - Parameter client: The TMDb client used for image configuration.
    func backdropURL(client: TMDbClient) async throws -> URL? {
        return try await client.imagesConfiguration.backdropURL(for: backdropPath)
    }
    
    /// Gets URL for the logo image.
    ///
    /// - Parameter client: The TMDb client used for image configuration.
    func logoURL(client: TMDbClient) async throws -> URL? {
        let imageResources = try await client.tvSeries.images(forTVSeries: id)
        let logoPath = imageResources.logos.first?.filePath
        return try await client.imagesConfiguration.logoURL(for: logoPath)
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
        logger.debug("Fetching basic info for season \(self.seasonNumber) of series \(parentSeriesID)")
        let seasonPoster: URL? = try await client.imagesConfiguration.posterURL(for: posterPath)
        logger.info("Successfully fetched basic info for season \(self.seasonNumber) of series \(parentSeriesID)")
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
        let url = try await client.imagesConfiguration.posterURL(for: posterPath)
        return url
    }
    
    var onAirDate: Date? { airDate }
    var linkToDetails: URL? { nil }
}

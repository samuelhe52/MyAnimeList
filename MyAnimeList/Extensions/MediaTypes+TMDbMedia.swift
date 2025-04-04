//
//  MediaTypes+TMDbMedia.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/29.
//

import Foundation
import TMDb

protocol TMDbMedia: Identifiable, Sendable, Equatable {
    func basicInfo(client: TMDbClient) async throws -> BasicInfo
    func posterURL(client: TMDbClient) async throws -> URL?
    func backdropURL(client: TMDbClient) async throws -> URL?
    
    var id: Int { get }
    var name: String { get }
    var overview: String? { get }
    var onAirDate: Date? { get }
    var linkToDetails: URL? { get }
}

extension TMDbClient {
    var imagesConfiguration: ImagesConfiguration {
        get async throws {
            let configurationService = configurations
            let apiConfiguration = try await configurationService.apiConfiguration()
            return apiConfiguration.images
        }
    }
}

extension Movie: TMDbMedia {
    /// Returns the basic information for the movie.
    ///
    /// - Parameters:
    ///   - client: The TMDb client used to fetch image configuration.
    /// - Returns: A `BasicInfo` struct containing metadata about the movie.
    func basicInfo(client: TMDbClient) async throws -> BasicInfo {
        let posterURL = try await posterURL(client: client)
        let backdropURL = try await backdropURL(client: client)
        
        return .init(name: title,
                     overview: overview,
                     posterURL: posterURL,
                     backdropURL: backdropURL,
                     tmdbID: id,
                     onAirDate: releaseDate,
                     linkToDetails: homepageURL,
                     entryType: .movie)
    }
    
    func backdropURL(client: TMDb.TMDbClient) async throws -> URL? {
        return try await client.imagesConfiguration.backdropURL(for: backdropPath)
    }
    
    func posterURL(client: TMDb.TMDbClient) async throws -> URL? {
        return try await client.imagesConfiguration.posterURL(for: posterPath)
    }
    
    var name: String { title }
    var onAirDate: Date? { releaseDate }
    var linkToDetails: URL? { homepageURL }
}

extension TVSeries: TMDbMedia {
    /// Returns the basic information for the TV series.
    ///
    /// - Parameters:
    ///   - client: The TMDb client used to fetch image configuration.
    /// - Returns: A `BasicInfo` struct containing metadata about the TV series.
    func basicInfo(client: TMDbClient) async throws -> BasicInfo {
        let posterURL = try await posterURL(client: client)
        let backdropURL = try await backdropURL(client: client)

        return BasicInfo(
            name: name,
            overview: overview,
            posterURL: posterURL,
            backdropURL: backdropURL,
            tmdbID: id,
            onAirDate: firstAirDate,
            linkToDetails: homepageURL,
            entryType: .tvSeries
        )
    }

    func posterURL(client: TMDbClient) async throws -> URL? {
        return try await client.imagesConfiguration.posterURL(for: posterPath)
    }

    func backdropURL(client: TMDbClient) async throws -> URL? {
        return try await client.imagesConfiguration.backdropURL(for: backdropPath)
    }
    
    var onAirDate: Date? { firstAirDate }
    var linkToDetails: URL? { homepageURL }
}

extension TVSeason: TMDbMedia {
    ///
    /// Returns the basic information for the TV season.
    ///
    /// - Parameters:
    ///   - client: The TMDb client used to fetch image configuration.
    /// - Returns: A `BasicInfo` struct containing metadata about the TV season.
    ///
    /// - Warning: The `backdropURL` is always `nil` because backdrop images are not typically associated with TV seasons.
    /// The `parentSeriesID` is set to `0` since the actual parent series ID cannot be inferred from a `TVSeason` instance alone.
    func basicInfo(client: TMDbClient) async throws -> BasicInfo {
        let posterURL = try await posterURL(client: client)
        
        return BasicInfo(
            name: name,
            overview: overview,
            posterURL: posterURL,
            backdropURL: nil,
            tmdbID: id,
            onAirDate: airDate,
            linkToDetails: nil,
            entryType: .tvSeason(seasonNumber: seasonNumber, parentSeriesID: 0)
        )
    }
    
    func posterURL(client: TMDbClient) async throws -> URL? {
        return try await client.imagesConfiguration.posterURL(for: posterPath)
    }
    
    func backdropURL(client: TMDbClient) async throws -> URL? {
        // TVSeason may not have a backdrop image; returning nil
        return nil
    }
    
    var onAirDate: Date? { airDate }
    var linkToDetails: URL? { nil }
}

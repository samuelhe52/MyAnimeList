//
//  MediaTypes+TMDbMedia.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/29.
//

import Foundation
import TMDb

protocol TMDbMedia {
    func basicInfo(client: TMDbClient) async throws -> BasicInfo
    func posterURL(client: TMDbClient) async throws -> URL?
    func backdropURL(client: TMDbClient) async throws -> URL?
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
    func basicInfo(client: TMDbClient) async throws -> BasicInfo {
        let posterURL = try await posterURL(client: client)
        let backdropURL = try await backdropURL(client: client)
        
        return .init(name: title,
                     overview: overview,
                     posterURL: posterURL,
                     backdropURL: backdropURL,
                     tmdbId: id,
                     linkToDetails: homepageURL,
                     entryType: .movie)
    }
    
    func backdropURL(client: TMDb.TMDbClient) async throws -> URL? {
        return try await client.imagesConfiguration.backdropURL(for: backdropPath)
    }
    
    func posterURL(client: TMDb.TMDbClient) async throws -> URL? {
        return try await client.imagesConfiguration.posterURL(for: posterPath)
    }
    
}

extension TVSeries: TMDbMedia {
    func basicInfo(client: TMDbClient) async throws -> BasicInfo {
        let posterURL = try await posterURL(client: client)
        let backdropURL = try await backdropURL(client: client)

        return BasicInfo(
            name: name,
            overview: overview,
            posterURL: posterURL,
            backdropURL: backdropURL,
            tmdbId: id,
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
}

extension TVSeason: TMDbMedia {
    func basicInfo(client: TMDbClient) async throws -> BasicInfo {
        let posterURL = try await posterURL(client: client)

        return BasicInfo(
            name: name,
            overview: overview,
            posterURL: posterURL,
            backdropURL: nil,
            tmdbId: id,
            linkToDetails: nil,
            entryType: .tvSeason
        )
    }

    func posterURL(client: TMDbClient) async throws -> URL? {
        return try await client.imagesConfiguration.posterURL(for: posterPath)
    }

    func backdropURL(client: TMDbClient) async throws -> URL? {
        // TVSeason may not have a backdrop image; returning nil
        return nil
    }
}

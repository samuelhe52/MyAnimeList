//
//  TMDbClient+ImageFetching.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/4/25.
//

import Foundation
import TMDb

struct ImageURLWithMetadata: Identifiable, Hashable {
    var metadata: ImageMetadata
    var url: URL
    
    var id: String { url.absoluteString }
}

/// Provides direct image URL fetching capabilities from TMDb API.
extension TMDbClient {
    /// Gets the current image configuration from TMDb API.
    ///
    /// The configuration contains base URLs and available sizes for different image types.
    var imagesConfiguration: ImagesConfiguration {
        get async throws {
            let configurationService = configurations
            let apiConfiguration = try await configurationService.apiConfiguration()
            return apiConfiguration.images
        }
    }
    
    enum ImageMetadataType {
        case logo
        case poster
        case backdrop
    }
    
    /// Converts image metadata resources into actual URLs.
    ///
    /// - Parameters:
    ///   - resources: Array of `ImageMetadata` objects to convert to URLs.
    ///   - imageType: The type of image being requested.
    /// - Returns: Array of valid URLs alongside with the original metadata for the requested images.
    func urlsFromImageMetadata(resources: [ImageMetadata], imageType: ImageMetadataType, idealWidth: Int = .max) async -> [ImageURLWithMetadata] {
        return await withTaskGroup(of: (ImageMetadata, URL?).self) { group in
            for resource in resources {
                group.addTask {
                    let url: URL?
                    switch imageType {
                    case .backdrop:
                        url = try? await self.imagesConfiguration.backdropURL(for: resource.filePath, idealWidth: idealWidth)
                    case .logo:
                        url = try? await self.imagesConfiguration.logoURL(for: resource.filePath, idealWidth: idealWidth)
                    case .poster:
                        url = try? await self.imagesConfiguration.posterURL(for: resource.filePath, idealWidth: idealWidth)
                    }
                    return (resource, url)
                }
            }

            var results: [ImageURLWithMetadata] = []
            for await result in group {
                if let url = result.1 {
                    results.append(.init(metadata: result.0, url: url))
                }
            }
            return results
        }
    }
    
    /// Fetches poster image URLs from an image collection.
    ///
    /// - Parameter collection: The `ImageCollection` containing poster images.
    /// - Returns: Array of URLs for the highest quality poster images.
    func posters(from collection: ImageCollection, idealWidth: Int = .max) async -> [ImageURLWithMetadata] {
        return await urlsFromImageMetadata(resources: collection.posters,
                                           imageType: .poster,
                                           idealWidth: idealWidth)
    }
    
    /// Fetches backdrop image URLs from an image collection.
    ///
    /// - Parameter collection: The `ImageCollection` containing backdrop images.
    /// - Returns: Array of URLs for the highest quality backdrop images.
    func backdrops(from collection: ImageCollection, idealWidth: Int = .max) async -> [ImageURLWithMetadata] {
        return await urlsFromImageMetadata(resources: collection.backdrops,
                                           imageType: .backdrop,
                                           idealWidth: .max)
    }
    
    /// Fetches logo image URLs from an image collection.
    ///
    /// - Parameter collection: The `ImageCollection` containing logo images.
    /// - Returns: Array of URLs for the highest quality logo images.
    func logos(from collection: ImageCollection, idealWidth: Int = .max) async -> [ImageURLWithMetadata] {
        return await urlsFromImageMetadata(resources: collection.logos,
                                           imageType: .logo,
                                           idealWidth: idealWidth)
    }
}

// Batch image fetching for Movies
extension TMDbClient {
    /// Gets URLs for all poster images associated with the movie.
    ///
    /// - Parameter client: The TMDb client used for image configuration.
    /// - Returns: Array of URLs for poster images.
    func posterURLs(forMovie id: Movie.ID, idealWidth: Int = .max) async throws -> [ImageURLWithMetadata] {
        let collection = try await movies.images(forMovie: id)
        return await posters(from: collection, idealWidth: idealWidth)
    }
    
    /// Gets URLs for all backdrop images associated with the movie.
    ///
    /// - Parameter client: The TMDb client used for image configuration.
    /// - Returns: Array of URLs for backdrop images.
    func backdropURLs(forMovie id: Movie.ID, idealWidth: Int = .max) async throws -> [ImageURLWithMetadata] {
        let collection = try await movies.images(forMovie: id)
        return await backdrops(from: collection, idealWidth: idealWidth)
    }
    
    /// Gets URLs for all logo images associated with the movie.
    ///
    /// - Parameter client: The TMDb client used for image configuration.
    /// - Returns: Array of URLs for logo images.
    func logoURLs(forMovie id: Movie.ID, idealWidth: Int = .max) async throws -> [ImageURLWithMetadata] {
        let collection = try await movies.images(forMovie: id)
        return await logos(from: collection, idealWidth: idealWidth)
    }
}

// Batch image fetching for TVSeries
extension TMDbClient {    
    /// Gets URLs for all poster images associated with the TV series.
    /// 
    /// - Parameter client: The TMDb client used for image configuration.
    /// - Returns: Array of URLs for poster images.
    func posterURLs(forTVSeries id: TVSeries.ID, idealWidth: Int = .max) async throws -> [ImageURLWithMetadata] {
        let collection = try await tvSeries.images(forTVSeries: id)
        return await posters(from: collection, idealWidth: idealWidth)
    }

    /// Gets URLs for all backdrop images associated with the TV series.
    /// 
    /// - Parameter client: The TMDb client used for image configuration.
    /// - Returns: Array of URLs for backdrop images.
    func backdropURLs(forTVSeries id: TVSeries.ID, idealWidth: Int = .max) async throws -> [ImageURLWithMetadata] {
        let collection = try await tvSeries.images(forTVSeries: id)
        return await backdrops(from: collection, idealWidth: idealWidth)
    }

    /// Gets URLs for all logo images associated with the TV series.
    /// 
    /// - Parameter client: The TMDb client used for image configuration.
    /// - Returns: Array of URLs for logo images.
    func logoURLs(forTVSeries id: TVSeries.ID, idealWidth: Int = .max) async throws -> [ImageURLWithMetadata] {
        let collection = try await tvSeries.images(forTVSeries: id)
        return await logos(from: collection, idealWidth: idealWidth)
    }
}

// Batched image fetching for Seasons
extension TMDbClient {
    /// Gets URLs for all poster images associated with the season.
    ///
    /// - Parameter client: The TMDb client used for image configuration.
    /// - Returns: Array of URLs for poster images.
    func posterURLs(forSeason seasonNumber: Int, inTVSeries parentSeriesID: Int, idealWidth: Int = .max) async throws -> [ImageURLWithMetadata] {
        let collection = try await tvSeasons.images(forSeason: seasonNumber,
                                                           inTVSeries: parentSeriesID)
        let urls = await urlsFromImageMetadata(resources: collection.posters, imageType: .poster, idealWidth: idealWidth)
        return urls
    }
}

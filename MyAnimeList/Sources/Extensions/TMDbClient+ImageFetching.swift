//
//  TMDbClient+ImageFetching.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/4/25.
//

import Foundation
import TMDb

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
    /// - Returns: Array of valid URLs for the requested images.
    func urlsFromImageMetadata(resources: [ImageMetadata], imageType: ImageMetadataType) async -> [URL] {
        return await withTaskGroup(of: URL?.self) { group in
            for resource in resources {
                group.addTask {
                    switch imageType {
                    case .backdrop:
                        try? await self.imagesConfiguration.backdropURL(for: resource.filePath)
                    case .logo:
                        try? await self.imagesConfiguration.logoURL(for: resource.filePath)
                    case .poster:
                        try? await self.imagesConfiguration.posterURL(for: resource.filePath)
                    }
                }
            }

            var urls: [URL] = []
            for await url in group {
                if let url = url {
                    urls.append(url)
                }
            }
            return urls
        }
    }
    
    /// Fetches poster image URLs from an image collection.
    ///
    /// - Parameter collection: The `ImageCollection` containing poster images.
    /// - Returns: Array of URLs for the highest quality poster images.
    func posters(from collection: ImageCollection) async -> [URL] {
        return await urlsFromImageMetadata(resources: collection.posters,
                                           imageType: .poster)
    }
    
    /// Fetches backdrop image URLs from an image collection.
    ///
    /// - Parameter collection: The `ImageCollection` containing backdrop images.
    /// - Returns: Array of URLs for the highest quality backdrop images.
    func backdrops(from collection: ImageCollection) async -> [URL] {
        return await urlsFromImageMetadata(resources: collection.backdrops,
                                           imageType: .backdrop)
    }
    
    /// Fetches logo image URLs from an image collection.
    ///
    /// - Parameter collection: The `ImageCollection` containing logo images.
    /// - Returns: Array of URLs for the highest quality logo images.
    func logos(from collection: ImageCollection) async -> [URL] {
        return await urlsFromImageMetadata(resources: collection.logos,
                                           imageType: .logo)
    }
}


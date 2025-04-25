//
//  TMDbClient+ImageFetching.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/4/25.
//

import Foundation
import TMDb

extension TMDbClient {
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
    
    func posters(from collection: ImageCollection) async -> [URL] {
        return await urlsFromImageMetadata(resources: collection.posters.filterAndSortByBestQuality,
                                           imageType: .poster)
    }
    
    func backdrops(from collection: ImageCollection) async -> [URL] {
        return await urlsFromImageMetadata(resources: collection.backdrops.filterAndSortByBestQuality,
                                           imageType: .backdrop)
    }
    
    func logos(from collection: ImageCollection) async -> [URL] {
        return await urlsFromImageMetadata(resources: collection.logos.filterAndSortByBestQuality,
                                           imageType: .logo)
    }
}


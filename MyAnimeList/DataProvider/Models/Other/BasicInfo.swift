//
//  BasicInfo.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation

struct BasicInfo: Equatable, Identifiable, Hashable {
    var name: String
    var overview: String?
    var posterPath: URL?
    var posterURL: URL?
    var backdropURL: URL?
    var logoURL: URL?
    var tmdbID: Int
    var onAirDate: Date?
    var linkToDetails: URL?
    
    var type: AnimeType
    
    mutating func updatePosterURL(width: Int? = nil) async throws {
        if let width {
            self.posterURL = try await InfoFetcher.shared.tmdbClient
                .imagesConfiguration
                .posterURL(for: posterPath, idealWidth: width)
        } else {
            self.posterURL = try await InfoFetcher.shared.tmdbClient
                .imagesConfiguration
                .posterURL(for: posterPath)
        }
    }
    
    var id: Int { tmdbID }
}

extension Array where Element == BasicInfo {
    mutating func updatePosterURLs(width: Int? = nil) async throws {
        for index in self.indices {
            try await self[index].updatePosterURL(width: width)
        }
    }
}

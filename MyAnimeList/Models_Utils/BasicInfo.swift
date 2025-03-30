//
//  BasicInfo.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation

struct BasicInfo: Equatable, Identifiable {
    var name: String
    var overview: String?
    var posterPath: URL?
    var posterURL: URL?
    var backdropURL: URL?
    var tmdbId: Int
    var onAirDate: Date?
    var linkToDetails: URL?
    
    var entryType: EntryType
    
    mutating func updatePosterURL() async throws {
        self.posterURL = try await InfoFetcher.shared.tmdbClient
            .imagesConfiguration
            .posterURL(for: posterPath)
    }
    
    var id: Int { tmdbId }
}

extension Array where Element == BasicInfo {
    mutating func updatePosterURLs() async throws {
        for index in self.indices {
            try await self[index].updatePosterURL()
        }
    }
}

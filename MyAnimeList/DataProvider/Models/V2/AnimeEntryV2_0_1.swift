//
//  AnimeEntryV2_0_1.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/5.
//

import Foundation
import SwiftData

extension SchemaV2_0_1 {
    @Model
    final class AnimeEntry {
        // MARK: Metadata
        var name: String
        var overview: String?
        var onAirDate: Date?
        var entryType: MediaTypeMetadata
        
        /// Link ot the homepage of the anime.
        var linkToDetails: URL?
        
        var posterURL: URL?
        var backdropURL: URL?
        
        /// The unique TMDB id for this entry.
        @Attribute(.unique) var tmdbID: Int
        
        // MARK: User-specific properties
        /// Use parent series' poster instead?
        var useSeriesPoster: Bool = false
        
        /// Date saved to library.
        var dateSaved: Date
        
        /// Date started watching.
        var dateStarted: Date?
        
        /// Date marked finished.
        var dateFinished: Date?
        
        /// Whether the entry is marked as favorite.
        var favorite: Bool = false
        
        /// Status for this entry: `wantToWatch`, `watching` or `watched`
        var status: Status {
            if dateStarted == nil && dateFinished == nil {
                return .unwatched
            } else if dateStarted != nil && dateFinished == nil {
                return .watching
            } else { return .watched }
        }
        
        init(name: String,
             overview: String? = nil,
             onAirDate: Date? = nil,
             entryType: MediaTypeMetadata,
             linkToDetails: URL? = nil,
             posterURL: URL? = nil,
             backdropURL: URL? = nil,
             tmdbID: Int,
             useSeriesPoster: Bool = false,
             dateSaved: Date? = nil,
             dateStarted: Date? = nil,
             dateFinished: Date? = nil) {
            self.name = name
            self.overview = overview
            self.onAirDate = onAirDate
            self.entryType = entryType
            self.linkToDetails = linkToDetails
            self.posterURL = posterURL
            self.backdropURL = backdropURL
            self.tmdbID = tmdbID
            self.useSeriesPoster = useSeriesPoster
            self.dateSaved = dateSaved ?? .now
            self.dateStarted = dateStarted
            self.dateFinished = dateFinished
        }
        
        static func template(id: Int = 0) -> Self {
            .init(name: "Template", entryType: .movie, tmdbID: id)
        }
    }
    
    enum Status: Equatable, CaseIterable {
        case unwatched
        case watching
        case watched
    }
}

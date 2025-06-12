//
//  AnimeEntryV2.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/4/12.
//

import Foundation
import SwiftData

extension SchemaV2 {
    @Model
    public final class AnimeEntry {
        // MARK: Metadata
        public var name: String
        public var overview: String?
        public var onAirDate: Date?
        public var entryType: MediaTypeMetadata
        
        /// Link ot the homepage of the anime.
        public var linkToDetails: URL?
        
        public var posterURL: URL?
        public var backdropURL: URL?
        
        /// The unique TMDB id for this entry.
        @Attribute(.unique, originalName: "id") public var tmdbID: Int
        
        // MARK: User-specific properties
        /// Date saved to library.
        public var dateSaved: Date
        
        /// Date started watching.
        public var dateStarted: Date?
        
        /// Date marked finished.
        public var dateFinished: Date?
        
        /// Whether the entry is marked as favorite.
        public var favorite: Bool = false
        
        /// Status for this entry: `wantToWatch`, `watching` or `watched`
        public var status: Status {
            if dateStarted == nil && dateFinished == nil {
                return .unwatched
            } else if dateStarted != nil && dateFinished == nil {
                return .watching
            } else { return .watched }
        }
        
        public init(name: String, overview: String? = nil, onAirDate: Date? = nil, entryType: MediaTypeMetadata, linkToDetails: URL? = nil, posterURL: URL? = nil, backdropURL: URL? = nil, tmdbID: Int, dateSaved: Date? = nil, dateStarted: Date? = nil, dateFinished: Date? = nil) {
            self.name = name
            self.overview = overview
            self.onAirDate = onAirDate
            self.entryType = entryType
            self.linkToDetails = linkToDetails
            self.posterURL = posterURL
            self.backdropURL = backdropURL
            self.tmdbID = tmdbID
            self.dateSaved = dateSaved ?? .now
            self.dateStarted = dateStarted
            self.dateFinished = dateFinished
        }
        
        public static func template(id: Int = 0) -> Self {
            .init(name: "Template", entryType: .movie, tmdbID: id)
        }
    }
    
    public enum Status: Equatable, CaseIterable {
        case unwatched
        case watching
        case watched
    }
}

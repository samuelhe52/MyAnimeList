//
//  AnimeEntryV1.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation
import SwiftData

extension SchemaV1 {
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
        @Attribute(.unique) public var id: Int

        // MARK: User-specific properties
        /// Date saved to library.
        public var dateSaved: Date

        /// Date started watching.
        public var dateStarted: Date?

        /// Date marked finished.
        public var dateFinished: Date?

        /// Whether the entry is marked as favorite.
        public var favorite: Bool = false

        /// Status for this entry: `wantToWatch`, `watching` or `watched`.
        public var status: Status {
            if dateStarted == nil && dateFinished == nil {
                return .unwatched
            } else if dateStarted != nil && dateFinished == nil {
                return .watching
            } else {
                return .watched
            }
        }

        public init(
            name: String, overview: String? = nil, onAirDate: Date? = nil,
            entryType: MediaTypeMetadata, linkToDetails: URL? = nil, posterURL: URL? = nil,
            backdropURL: URL? = nil, id: Int, dateSaved: Date? = nil, dateStarted: Date? = nil,
            dateFinished: Date? = nil
        ) {
            self.name = name
            self.overview = overview
            self.onAirDate = onAirDate
            self.entryType = entryType
            self.linkToDetails = linkToDetails
            self.posterURL = posterURL
            self.backdropURL = backdropURL
            self.id = id
            self.dateSaved = dateSaved ?? .now
            self.dateStarted = dateStarted
            self.dateFinished = dateFinished
        }

        public static var template: Self { .init(name: "Template", entryType: .movie, id: 0) }
    }

    public enum Status: Equatable, CaseIterable {
        case unwatched
        case watching
        case watched
    }
}

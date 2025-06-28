//
//  AnimeEntryV2_3_2.swift
//  DataProvider
//
//  Created by Samuel He on 2025/6/28.
//

import Foundation
import SwiftData

extension SchemaV2_3_2 {
    @Model
    public final class  AnimeEntry {
        // MARK: Anime Info
        public var name: String
        public var overview: String?
        public var onAirDate: Date?
        public var type: AnimeType
        
        /// Link ot the homepage of the anime.
        public var linkToDetails: URL?
        
        public var posterURL: URL?
        public var backdropURL: URL?
        
        /// The unique TMDB id for this entry.
        public var tmdbID: Int
        
        public var parentSeriesEntry: AnimeEntry? = nil
        
        /// Whether this entry should be displayed to user.
        public var onDisplay: Bool = true
        
        // MARK: User-specific properties
        
        /// Date saved to library.
        public var dateSaved: Date
        
        /// User's watch status for this entry.
        public var watchStatus: WatchStatus = WatchStatus.planToWatch
        
        /// Date started watching.
        public var dateStarted: Date?
        
        /// Date marked finished.
        public var dateFinished: Date?
        
        /// Whether the entry is marked as favorite.
        public var favorite: Bool = false

        /// Notes for this entry.
        public var notes: String = ""
        
        /// Whether the entry is using a custom poster image.
        public var usingCustomPoster: Bool = false
        
        public init(name: String,
                    overview: String? = nil,
                    onAirDate: Date? = nil,
                    type: AnimeType,
                    linkToDetails: URL? = nil,
                    posterURL: URL? = nil,
                    backdropURL: URL? = nil,
                    tmdbID: Int,
                    dateSaved: Date? = nil,
                    dateStarted: Date? = nil,
                    dateFinished: Date? = nil,
                    usingCustomPoster: Bool = false) {
            self.name = name
            self.overview = overview
            self.onAirDate = onAirDate
            self.type = type
            self.linkToDetails = linkToDetails
            self.posterURL = posterURL
            self.backdropURL = backdropURL
            self.tmdbID = tmdbID
            self.dateSaved = dateSaved ?? .now
            self.dateStarted = dateStarted
            self.dateFinished = dateFinished
            self.usingCustomPoster = usingCustomPoster
        }
        
        public static func template(id: Int = 0) -> Self {
            .init(name: "Template", type: .movie, tmdbID: id)
        }
        
        public enum WatchStatus: Equatable, CaseIterable, Codable {
            case planToWatch
            case watching
            case watched
        }
    }
}

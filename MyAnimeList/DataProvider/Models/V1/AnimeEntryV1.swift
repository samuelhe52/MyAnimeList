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
        @Attribute(.unique) var id: Int
        
        // MARK: User-specific properties
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
        
        init(name: String, overview: String? = nil, onAirDate: Date? = nil, entryType: MediaTypeMetadata, linkToDetails: URL? = nil, posterURL: URL? = nil, backdropURL: URL? = nil, id: Int, dateSaved: Date? = nil, dateStarted: Date? = nil, dateFinished: Date? = nil) {
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
        
        init(fromInfo info: BasicInfo) {
            name = info.name
            overview = info.overview
            linkToDetails = info.linkToDetails
            posterURL = info.posterURL
            backdropURL = info.backdropURL
            onAirDate = info.onAirDate
            entryType = info.typeMetadata
            id = info.tmdbID
            dateSaved = .now
        }
        
        func update(from info: BasicInfo) {
            name = info.name
            overview = info.overview ?? self.overview
            linkToDetails = info.linkToDetails ?? self.linkToDetails
            posterURL = info.posterURL ?? self.posterURL
            backdropURL = info.backdropURL ?? self.backdropURL
            onAirDate = info.onAirDate ?? self.onAirDate
            entryType = info.typeMetadata
            id = info.tmdbID
        }
        
        /// - Note: `dateSaved` and `id` is not updated in this method.
        func update(from other: AnimeEntry) {
            name = other.name
            overview = other.overview
            onAirDate = other.onAirDate
            entryType = other.entryType
            linkToDetails = other.linkToDetails
            posterURL = other.posterURL
            backdropURL = other.backdropURL
            // Date saved and id is not updated.
            dateStarted = other.dateStarted
            dateFinished = other.dateFinished
            favorite = other.favorite
        }
        
        var basicInfo: BasicInfo {
            BasicInfo(name: name,
                      overview: overview,
                      posterURL: posterURL,
                      backdropURL: backdropURL,
                      tmdbID: id,
                      onAirDate: onAirDate,
                      linkToDetails: linkToDetails,
                      typeMetadata: entryType)
        }
        
        static var template: Self { .init(name: "Template", entryType: .movie, id: 0) }
    }
    
    enum Status: Equatable, CaseIterable {
        case unwatched
        case watching
        case watched
    }
}

//
//  AnimeEntry+Helpers.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/10.
//

import Foundation
import SwiftData

extension AnimeEntry {
    /// Whether this entry is a season from a series.
    public var isSeason: Bool {
        switch self.type {
        case .season: return true
        default : return false
        }
    }
    
    /// The season number of this entry, if it is an `.season`.
    /// - Note: "0" is for "Specials".
    public var seasonNumber: Int? { type.seasonNumber }
    
    /// The TMDB ID for the parent series of this season, if this entry is of type `.season`
    public var parentSeriesID: Int? { type.parentSeriesID }
    
    /// - Note: `dateSaved` and `id` is not updated in this method.
    public func update(from other: AnimeEntry) {
        name = other.name
        overview = other.overview
        onAirDate = other.onAirDate
        type = other.type
        linkToDetails = other.linkToDetails
        posterURL = other.posterURL
        backdropURL = other.backdropURL
        // Date saved and id is not updated.
        dateStarted = other.dateStarted
        dateFinished = other.dateFinished
        favorite = other.favorite
    }
}

extension Collection where Element == AnimeEntry {
    public subscript(id: Int) -> AnimeEntry? {
        guard id != 0 else { return nil }
        return self.first { $0.tmdbID == id }
    }
    
    public subscript(id: PersistentIdentifier) -> AnimeEntry? {
        return self.first { $0.id == id }
    }
}


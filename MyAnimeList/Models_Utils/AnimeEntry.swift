//
//  AnimeEntry.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation
import TMDb

struct AnimeEntry: Identifiable {
    var name: String
    var mediaType: MediaType
    var overview: String = "No overview available."
    
    /// Date added to library.
    var dateAdded: Date?
    
    /// Date marked finished.
    var dateFinished: Date?
    
    /// Link ot the homepage of the anime.
    var linkToDetails: URL?
    
    /// The saved season numbers of a TV series. This property should only be non-nil for entries with the mediatype of `.tvSeries`.
    var savedSeasons: [Int]?
    
    var posterURL: URL?
    var backdropURL: URL?
    var tmdbId: Int?
    
    var id: UUID = .init()
    
    mutating func updateInfo(from info: BasicMediaInfo) {
        name = info.name
        overview = info.overview ?? "This anime has no overview."
        linkToDetails = info.linkToDetails
        posterURL = info.posterURL
        backdropURL = info.backdropURL
        tmdbId = info.tmdbId
    }
    
    enum MediaType: String, CaseIterable, CustomStringConvertible {
        case tvSeries
        case movie
        
        var description: String {
            switch self {
            case .tvSeries:
                return "TV Series"
            case .movie:
                return "Movie"
            }
        }
    }
}

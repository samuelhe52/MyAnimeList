//
//  AnimeItem.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation
import TMDb

struct AnimeItem: Identifiable {
    var name: String
    var mediaType: MediaType
    
    var overview: String = "No overview available."
    var dateAdded: Date?
    var dateFinished: Date?
    var linkToDetails: URL?
    var posterURL: URL?
    var tmdbId: Int?
    
    var id: UUID = .init()
    
    mutating func updateInfo(from info: BasicMediaInfo) {
        name = info.name
        overview = info.overview ?? "This anime has no overview."
        linkToDetails = info.linkToDetails
        posterURL = info.posterURL
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

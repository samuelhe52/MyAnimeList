//
//  AnimeEntry.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation
import TMDb

struct AnimeEntry: Identifiable, Codable {
    var name: String
    var overview: String?
    var onAirDate: Date?
    var entryType: MediaTypeMetadata
    
    /// Link ot the homepage of the anime.
    var linkToDetails: URL?
    
    var posterURL: URL?
    var backdropURL: URL?
    
    /// The unique TMDB id for this entry.
    var id: Int
    
    /// Date added to library.
    var dateAdded: Date?
    
    /// Date marked finished.
    var dateFinished: Date?
    
    /// Whether the entry is marked as favorite.
    var favorite: Bool = false
    
    init(name: String, overview: String? = nil, onAirDate: Date? = nil, entryType: MediaTypeMetadata, linkToDetails: URL? = nil, posterURL: URL? = nil, backdropURL: URL? = nil, id: Int, dateAdded: Date? = nil, dateFinished: Date? = nil) {
        self.name = name
        self.overview = overview
        self.onAirDate = onAirDate
        self.entryType = entryType
        self.linkToDetails = linkToDetails
        self.posterURL = posterURL
        self.backdropURL = backdropURL
        self.id = id
        self.dateAdded = dateAdded
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
    }
    
    mutating func update(fromInfo info: BasicInfo) {
        name = info.name
        overview = info.overview ?? self.overview
        linkToDetails = info.linkToDetails ?? self.linkToDetails
        posterURL = info.posterURL ?? self.posterURL
        backdropURL = info.backdropURL ?? self.backdropURL
        onAirDate = info.onAirDate ?? self.onAirDate
        entryType = info.typeMetadata
        id = info.tmdbID
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
    
    static let template: Self = .init(name: "Template", entryType: .movie, id: 0)
}

enum MediaTypeMetadata: CustomStringConvertible, Codable, Equatable {
    case tvSeason(seasonNumber: Int, parentSeriesID: Int)
    case movie
    case tvSeries
    
    var description: String {
        switch self {
        case .tvSeason(let seasonNumber, let parentSeriesID):
            return "TV Season, Season \(seasonNumber), Parent Series ID: \(parentSeriesID)"
        case .movie:
            return "Movie"
        case .tvSeries:
            return "TV Series"
        }
    }
}

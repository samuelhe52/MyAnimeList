//
//  MediaTypeMetadata.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/4/5.
//

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

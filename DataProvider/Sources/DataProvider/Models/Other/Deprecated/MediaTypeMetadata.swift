//
//  MediaTypeMetadata.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/4/5.
//

/// - Warning: Renamed to `AnimeType`.
public enum MediaTypeMetadata: CustomStringConvertible, Codable, Equatable, Hashable {
    case tvSeason(seasonNumber: Int, parentSeriesID: Int)
    case movie
    case tvSeries

    public var description: String {
        switch self {
        case .tvSeason(let seasonNumber, let parentSeriesID):
            return "TV Season, Season \(seasonNumber), Parent Series ID: \(parentSeriesID)"
        case .movie:
            return "Movie"
        case .tvSeries:
            return "TV Series"
        }
    }

    public var seasonNumber: Int? {
        switch self {
        case .tvSeason(let seasonNumber, parentSeriesID: _):
            return seasonNumber
        default:
            return nil
        }
    }

    public var parentSeriesID: Int? {
        switch self {
        case .tvSeason(seasonNumber: _, let parentSeriesID):
            return parentSeriesID
        default:
            return nil
        }
    }
}

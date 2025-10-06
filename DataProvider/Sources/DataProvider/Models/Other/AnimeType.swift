//
//  AnimeType.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/10.
//

import Foundation

public enum AnimeType: CustomStringConvertible, Codable, Equatable, Hashable, Sendable {
    case season(seasonNumber: Int, parentSeriesID: Int)
    case movie
    case series

    public var description: String {
        switch self {
        case .season(let seasonNumber, let parentSeriesID):
            return "TV Season, Season \(seasonNumber), Parent Series ID: \(parentSeriesID)"
        case .movie:
            return "Movie"
        case .series:
            return "TV Series"
        }
    }

    public var seasonNumber: Int? {
        switch self {
        case .season(let seasonNumber, parentSeriesID: _):
            return seasonNumber
        default:
            return nil
        }
    }

    public var parentSeriesID: Int? {
        switch self {
        case .season(seasonNumber: _, let parentSeriesID):
            return parentSeriesID
        default:
            return nil
        }
    }
}

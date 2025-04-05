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
    
    static let template: Self = .init(name: "Template", entryType: .movie, id: 0)
    
    mutating func updateInfo(fromInfo info: BasicInfo) {
        name = info.name
        overview = info.overview ?? self.overview
        linkToDetails = info.linkToDetails ?? self.linkToDetails
        posterURL = info.posterURL ?? self.posterURL
        backdropURL = info.backdropURL ?? self.backdropURL
        onAirDate = info.onAirDate ?? self.onAirDate
        entryType = info.typeMetadata
        id = info.tmdbID
    }

    mutating func refreshInfo(fetcher: InfoFetcher) async throws {
        let info = try await fetchInfo(fetcher: fetcher)
        updateInfo(fromInfo: info)
    }
    
    func fetchInfo(fetcher: InfoFetcher) async throws -> BasicInfo {
        switch entryType {
        case .tvSeason(let seasonNumber, let parentSeriesID):
            return try await tvSeasonInfo(seasonNumber: seasonNumber, parentSeriesID: parentSeriesID)
        case .movie:
            return try await movieInfo()
        case .tvSeries:
            return try await tvSeriesInfo()
        }
        
        func tvSeasonInfo(seasonNumber: Int, parentSeriesID: Int) async throws -> BasicInfo {
            try await Task {
                let language = await fetcher.language
                let season = try await fetcher.tmdbClient.tvSeasons.details(forSeason: seasonNumber,
                                                                            inTVSeries: parentSeriesID,
                                                                            language: language.rawValue)
                let parentSeries = try await fetcher.tmdbClient.tvSeries.details(forTVSeries: parentSeriesID,
                                                                                 language: language.rawValue)
                var basicInfo = try await season.basicInfo(client: fetcher.tmdbClient)
                // Use the parent series' backdrop image and homepage for the season.
                basicInfo.backdropURL = try await parentSeries.backdropURL(client: fetcher.tmdbClient)
                basicInfo.linkToDetails = parentSeries.homepageURL
                return basicInfo
            }.value
        }

        func movieInfo() async throws -> BasicInfo {
            try await Task {
                let language = await fetcher.language
                let movie = try await fetcher.tmdbClient.movies.details(forMovie: id, language: language.rawValue)
                return try await movie.basicInfo(client: fetcher.tmdbClient)
            }.value
        }

        func tvSeriesInfo() async throws -> BasicInfo {
            try await Task {
                let language = await fetcher.language
                let season = try await fetcher.tmdbClient.tvSeries.details(forTVSeries: id, language: language.rawValue)
                return try await season.basicInfo(client: fetcher.tmdbClient)
            }.value
        }
    }
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

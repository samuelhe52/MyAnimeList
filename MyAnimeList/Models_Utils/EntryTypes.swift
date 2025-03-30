//
//  EntryTypes.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/29.
//

import Foundation
import TMDb

enum EntryType: String, CaseIterable, CustomStringConvertible {
    case tvSeason
    case movie
    case tvSeries
    
    var description: String {
        switch self {
        case .tvSeason:
            return "TV Season"
        case .movie:
            return "Movie"
        case .tvSeries:
            return "TV Series"
        }
    }
}

struct MovieEntry: AnimeEntry {
    var name: String
    var overview: String?
    var dateAdded: Date?
    var dateFinished: Date?
    var linkToDetails: URL?
    var posterURL: URL?
    var backdropURL: URL?
    var id: Int
    
    mutating func updateInfo(fromInfo info: BasicInfo) {
        name = info.name
        overview = info.overview ?? self.overview
        linkToDetails = info.linkToDetails ?? self.linkToDetails
        posterURL = info.posterURL ?? self.posterURL
        backdropURL = info.backdropURL ?? self.backdropURL
        id = info.tmdbId
    }
    
    func fetchMetadata(fetcher: InfoFetcher) async throws -> BasicInfo {
        try await Task {
            let language = await fetcher.language
            let movie = try await fetcher.tmdbClient.movies.details(forMovie: id, language: language.rawValue)
            return try await movie.basicInfo(client: fetcher.tmdbClient)
        }.value
    }
}

struct TVSeasonEntry: AnimeEntry {
    var name: String
    var overview: String?
    var dateAdded: Date?
    var dateFinished: Date?
    var linkToDetails: URL?
    var posterURL: URL?
    var backdropURL: URL?
    var id: Int
    
    var parentSeriesId: Int
    var seasonNumber: Int
    
    private func parentSeriesInfo(fetcher: InfoFetcher) async throws -> BasicInfo {
        return try await fetcher.tmdbClient.tvSeries
            .details(forTVSeries: parentSeriesId,
                     language: fetcher.language.rawValue)
            .basicInfo(client: fetcher.tmdbClient)
    }
    
    func parentSeries(fetcher: InfoFetcher) async throws -> TVSeriesEntry {
        let seriesInfo = try await parentSeriesInfo(fetcher: fetcher)
        var entry = TVSeriesEntry(name: seriesInfo.name, id: seriesInfo.tmdbId)
        entry.updateInfo(fromInfo: seriesInfo)
        return entry
    }
    
    mutating func updateInfo(fromInfo info: BasicInfo) {
        name = info.name
        overview = info.overview ?? self.overview
        linkToDetails = info.linkToDetails ?? self.linkToDetails
        posterURL = info.posterURL ?? self.posterURL
        backdropURL = info.backdropURL ?? self.backdropURL
        id = info.tmdbId
    }
    
    func fetchMetadata(fetcher: InfoFetcher) async throws -> BasicInfo {
        try await Task {
            let language = await fetcher.language
            let season = try await fetcher.tmdbClient.tvSeasons.details(forSeason: seasonNumber,
                                                                        inTVSeries: parentSeriesId,
                                                                        language: language.rawValue)
            let parentSeries = try await fetcher.tmdbClient.tvSeries.details(forTVSeries: parentSeriesId,
                                                                             language: language.rawValue)
            var basicInfo = try await season.basicInfo(client: fetcher.tmdbClient)
            // Use the parent series' backdrop image and homepage for the season.
            basicInfo.backdropURL = try await parentSeries.backdropURL(client: fetcher.tmdbClient)
            basicInfo.linkToDetails = parentSeries.homepageURL
            return basicInfo
        }.value
    }
}

struct TVSeriesEntry: AnimeEntry {
    var name: String
    var overview: String?
    var dateAdded: Date?
    var dateFinished: Date?
    var linkToDetails: URL?
    var posterURL: URL?
    var backdropURL: URL?
    var id: Int
    
    mutating func updateInfo(fromInfo info: BasicInfo) {
        name = info.name
        overview = info.overview ?? self.overview
        linkToDetails = info.linkToDetails ?? self.linkToDetails
        posterURL = info.posterURL ?? self.posterURL
        backdropURL = info.backdropURL ?? self.backdropURL
        id = info.tmdbId
    }
    
    func fetchMetadata(fetcher: InfoFetcher) async throws -> BasicInfo {
        try await Task {
            let language = await fetcher.language
            let season = try await fetcher.tmdbClient.tvSeries.details(forTVSeries: id, language: language.rawValue)
            return try await season.basicInfo(client: fetcher.tmdbClient)
        }.value
    }
}

extension AnimeEntry {
    mutating func refreshInfo(fetcher: InfoFetcher) async throws {
        let info = try await fetchMetadata(fetcher: fetcher)
        updateInfo(fromInfo: info)
    }
}

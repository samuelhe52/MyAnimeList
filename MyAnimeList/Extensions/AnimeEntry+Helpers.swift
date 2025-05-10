//
//  AnimeEntry+Helpers.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/10.
//

import Foundation

extension AnimeEntry {
    convenience init(fromInfo info: BasicInfo) {
        self.init(name: info.name,
                  overview: info.overview,
                  onAirDate: info.onAirDate,
                  type: info.type,
                  linkToDetails: info.linkToDetails,
                  posterURL: info.posterURL,
                  backdropURL: info.backdropURL,
                  tmdbID: info.tmdbID,
                  dateSaved: .now)
    }
    
    /// Status for this entry: `wantToWatch`, `watching` or `watched`.
    var status: Status {
        if dateStarted == nil && dateFinished == nil {
            return .unwatched
        } else if dateStarted != nil && dateFinished == nil {
            return .watching
        } else { return .watched }
    }
    
    /// Whether this entry is a season from a series.
    var isSeason: Bool {
        switch self.type {
        case .season: return true
        default : return false
        }
    }
    
    func update(from info: BasicInfo) {
        name = info.name
        overview = info.overview ?? self.overview
        linkToDetails = info.linkToDetails ?? self.linkToDetails
        posterURL = info.posterURL ?? self.posterURL
        backdropURL = info.backdropURL ?? self.backdropURL
        onAirDate = info.onAirDate ?? self.onAirDate
        type = info.type
        tmdbID = info.tmdbID
    }
    
    /// - Note: `dateSaved` and `id` is not updated in this method.
    func update(from other: AnimeEntry) {
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
    
    var basicInfo: BasicInfo {
        BasicInfo(name: name,
                  overview: overview,
                  posterURL: posterURL,
                  backdropURL: backdropURL,
                  tmdbID: tmdbID,
                  onAirDate: onAirDate,
                  linkToDetails: linkToDetails,
                  type: type)
    }
    
    @MainActor
    func switchPoster(language: Language) async throws {
        switch type {
        case .season(let seasonNumber, let parentSeriesID):
            let fetcher = InfoFetcher()
            if !useSeriesPoster {
                let series = try await fetcher.tvSeries(parentSeriesID, language: language)
                let url = try await fetcher.tmdbClient.imagesConfiguration.posterURL(for: series.posterPath)
                useSeriesPoster = true
                posterURL = url
            } else {
                let season = try await fetcher.tvSeason(parentSeriesID,
                                                             seasonNumber: seasonNumber,
                                                             language: language)
                let url = try await fetcher.tmdbClient.imagesConfiguration.posterURL(for: season.posterPath)
                useSeriesPoster = false
                posterURL = url
            }
        default: return
        }
    }
}

extension Collection where Element == AnimeEntry {
    subscript(id: Int) -> AnimeEntry? {
        guard id != 0 else { return nil }
        return self.first { $0.tmdbID == id }
    }
}


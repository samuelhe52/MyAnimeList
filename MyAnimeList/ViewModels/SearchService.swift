//
//  SearchService.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/5.
//

import Foundation
import SwiftUI

@Observable @MainActor
class SearchService {
    let fetcher: InfoFetcher = .bypassGFWForTMDbAPI
    var status: Status = .idle
    var query: String
    var movieResults: [SearchResult] = []
    var seriesResults: [SearchResult: [SearchResult]] = [:]
    
    init(query: String = UserDefaults.standard.string(forKey: .searchPageQuery) ?? "") {
        self.query = query
    }
    
    func updateSearchResults(language: Language) async throws {
        UserDefaults.standard.set(query, forKey: .searchPageQuery)
        guard !query.isEmpty else { return }
        let currentQuery = query
        status = .fetching
        let movies = try await fetcher.searchMovies(name: currentQuery, language: language)
        let tvSeries = try await fetcher.searchTVSeries(name: currentQuery, language: language)
        
        var searchMovieResults = movies.map { movie in
            SearchResult(name: movie.title,
                         overview: movie.overview,
                         posterPath: movie.posterPath,
                         tmdbID: movie.id,
                         onAirDate: movie.releaseDate,
                         typeMetadata: .movie)
        }
        var searchTVSeriesResults = tvSeries.map { series in
            SearchResult(name: series.name,
                         overview: series.overview,
                         posterPath: series.posterPath,
                         tmdbID: series.id,
                         onAirDate: series.firstAirDate,
                         typeMetadata: .tvSeries)
        }
        
        // The poster displayed here is small and we use smaller sizes
        // to reduce network overhead.
        try await searchMovieResults.updatePosterURLs(width: 200)
        try await searchTVSeriesResults.updatePosterURLs(width: 200)
        
        if currentQuery == query {
            withAnimation {
                movieResults = searchMovieResults
            }
            seriesResults = [:]
            await withTaskGroup(of: Void.self) { group in
                for series in searchTVSeriesResults {
                    group.addTask {
                        let seasons = try? await fetchSeasons(seriesInfo: series, language: language)
                        await MainActor.run {
                            withAnimation {
                                self.seriesResults[series] = seasons ?? []
                            }
                        }
                    }
                }
            }
        }
        status = .done
        
        func fetchSeasons(seriesInfo info: BasicInfo, language: Language) async throws -> [BasicInfo] {
            let series = try await InfoFetcher.shared.fetchTVSeries(info.tmdbID, language: language)
            guard let seasons = series.seasons else { return [] }
            let infos = try await withThrowingTaskGroup(of: BasicInfo.self) { group in
                var results: [BasicInfo] = []
                for season in seasons {
                    group.addTask {
                        var seasonInfo = try await season.basicInfo(client: InfoFetcher.shared.tmdbClient)
                        seasonInfo.linkToDetails = info.linkToDetails
                        seasonInfo.backdropURL = info.backdropURL
                        seasonInfo.logoURL = info.logoURL
                        seasonInfo.typeMetadata = .tvSeason(seasonNumber: season.seasonNumber,
                                                            parentSeriesID: info.tmdbID)
                        return seasonInfo
                    }
                }
                for try await result in group {
                    results.append(result)
                }
                return results
            }
            return infos
        }
    }
    
    enum Status: Equatable {
        case idle
        case fetching
        case done
    }
}

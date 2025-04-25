//
//  MyAnimeListTests.swift
//  MyAnimeListTests
//
//  Created by Samuel He on 2024/12/8.
//

import Testing
@testable import MyAnimeList

struct MyAnimeListTests {
    let fetcher: InfoFetcher = .bypassGFWForTMDbAPI
    let language: Language = .japanese
    
    @Test func testFetchInfo() async throws {
        guard let result = try await fetcher.searchTVSeries(name: "K-ON!", language: language).first else { fatalError() }
        let series = try await fetcher.tmdbClient.tvSeries
            .details(forTVSeries: result.id, language: language.rawValue)
        let seasons = series.seasons!
        print(series.id)
        for season in seasons {
            print("name: \(season.name), id:\(season.id)")
        }
    }

    @Test func imageTest() async throws {
        guard let result = try await fetcher.searchMovies(name: "你的名字", language: language).first else { fatalError() }
        let images = try await fetcher.tmdbClient.movies.images(forMovie: result.id, filter: .init(languages: ["ja"]))
        images.posters.filter { $0.languageCode == "ja" }.forEach {
            print($0.filePath)
            print($0.languageCode ?? "nil")
            print($0.voteAverage ?? "nil")
            print($0.voteCount ?? "nil")
            print($0.height)
            print("-------------------------------------------")
        }
    }
}

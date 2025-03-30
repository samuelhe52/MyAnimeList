//
//  MyAnimeListTests.swift
//  MyAnimeListTests
//
//  Created by Samuel He on 2024/12/8.
//

import Testing
@testable import MyAnimeList

struct MyAnimeListTests {

    @Test func testFetchInfo() async throws {
        let fetcher: InfoFetcher = .init()
        let language = await fetcher.language
        guard let result = try await fetcher.searchTVSeries(name: "K-ON!").first else { fatalError() }
        let series = try await fetcher.tmdbClient.tvSeries
            .details(forTVSeries: result.id, language: language.rawValue)
        let seasons = series.seasons!
        for season in seasons {
            try await print(season.basicInfo(client: fetcher.tmdbClient))
        }
    }

}

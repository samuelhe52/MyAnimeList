//
//  MyAnimeListTests.swift
//  MyAnimeListTests
//
//  Created by Samuel He on 2024/12/8.
//

import Foundation
import ZIPFoundation
import Testing
@testable import MyAnimeList
@testable import DataProvider

struct MyAnimeListTests {
    let fetcher = InfoFetcher()
    let language: Language = .japanese
    @MainActor let fileManager = FileManager.default
    @MainActor let dataProvider = DataProvider()
    @MainActor let backupManager = BackupManager()
    
    @Test func testFetchInfo() async throws {
        guard let result = try await fetcher.searchTVSeries(name: "Frieren", language: language).first else { fatalError() }
        let series = try await fetcher.tmdbClient.tvSeries
            .details(forTVSeries: result.id, language: language.rawValue)
        let info = try await series.basicInfo(client: fetcher.tmdbClient)
        let entry = AnimeEntry(fromInfo: info)
        print(entry.debugDescription)
    }

    @Test func imageTest() async throws {
        guard let result = try await fetcher.searchTVSeries(name: "CLANNAD", language: language).first else { fatalError() }
        let images = try await fetcher.tmdbClient.tvSeries.images(forTVSeries: result.id)
        images.posters.filter { $0.languageCode == "ja" }.forEach {
            print($0.filePath)
            print($0.languageCode ?? "nil")
            print($0.voteAverage ?? "nil")
            print($0.voteCount ?? "nil")
            print($0.height)
            print("-------------------------------------------")
        }
    }
    
    @Test @MainActor func testBackup() throws {
        let backupURL = try backupManager.createBackup()
        let parentDirectoryURL = backupURL.deletingLastPathComponent()
        print(backupURL.path())
        print(fileManager.fileExists(atPath: backupURL.path()))
        try print(fileManager.attributesOfItem(atPath: backupURL.path())[.size] as! NSNumber)
        try fileManager.unzipItem(at: backupURL, to: parentDirectoryURL)
        try print(fileManager.contentsOfDirectory(atPath: parentDirectoryURL.path()).filter({ $0.contains("default") }))
    }
}

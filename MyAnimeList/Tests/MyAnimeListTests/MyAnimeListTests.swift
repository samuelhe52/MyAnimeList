//
//  MyAnimeListTests.swift
//  MyAnimeListTests
//
//  Created by Samuel He on 2024/12/8.
//

import Foundation
import SwiftData
import Testing
import UIKit
import ZIPFoundation

@testable import DataProvider
@testable import MyAnimeList

struct MyAnimeListTests {
    let fetcher = InfoFetcher()
    let language: Language = .japanese
    @MainActor let fileManager = FileManager.default
    @MainActor let dataProviderDefault = DataProvider.default
    @MainActor let dataProviderForPreview = DataProvider.forPreview
    @MainActor let backupManager = BackupManager(dataProvider: .forPreview)

    @Test func testFetchInfo() async throws {
        guard
            let result = try await fetcher.searchTVSeries(name: "Frieren", language: language).first
        else { fatalError() }
        let series = try await fetcher.tmdbClient.tvSeries
            .details(forTVSeries: result.id, language: language.rawValue)
        let info = try await series.basicInfo(client: fetcher.tmdbClient)
        let entry = AnimeEntry(fromInfo: info)
        print(entry.debugDescription)
    }

    @Test func imageTest() async throws {
        guard
            let result = try await fetcher.searchTVSeries(name: "CLANNAD", language: language).first
        else { fatalError() }
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
        try print(
            fileManager.contentsOfDirectory(atPath: parentDirectoryURL.path()).filter({
                $0.contains("default")
            }))
    }

    @Test @MainActor func inspectDataStoreDirectory() throws {
        let url = dataProviderDefault.url.deletingLastPathComponent()
        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        for item in contents {
            print(item.lastPathComponent)
        }
    }

    struct UserInfoRestoration: Codable {
        let tmdbID: Int
        let name: String
        let type: AnimeType
        let customPosterURL: URL?
        let userInfo: UserEntryInfo
    }

    @Test @MainActor func exportAllUserDataToClipboard() throws {
        let allEntries = try dataProviderDefault.getAllModels(ofType: AnimeEntry.self).filter {
            $0.onDisplay
        }
        let userInfos: [UserInfoRestoration] = allEntries.map {
            UserInfoRestoration(
                tmdbID: $0.tmdbID,
                name: $0.name,
                type: $0.type,
                customPosterURL: $0.userInfo.usingCustomPoster ? $0.posterURL : nil,
                userInfo: $0.userInfo)
        }
        // Pretty print JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(userInfos)
        let jsonString = String(data: data, encoding: .utf8)!
        UIPasteboard.general.string = jsonString
    }

    @Test @MainActor func restoreEntriesFromClipboardData() async throws {
        let jsonData = UIPasteboard.general.string!.data(using: .utf8)!
        let store = LibraryStore(dataProvider: dataProviderDefault)
        let userInfos = try JSONDecoder().decode(
            [UserInfoRestoration].self,
            from: jsonData)
        guard userInfos.count == 102 else { fatalError("Unexpected number of entries") }
        for (index, info) in userInfos.enumerated() {
            guard let id = try await store.createNewEntry(tmdbID: info.tmdbID, type: info.type) else {
                fatalError("Failed to create entry for \(info.name)")
            }
            print("Progress: \(index + 1)/102")
            let descriptor = FetchDescriptor<AnimeEntry>(
                predicate: #Predicate<AnimeEntry> {
                    $0.id == id
                })
            guard
                let entry =
                    try dataProviderDefault
                    .dataHandler.modelContext.fetch(descriptor).first
            else {
                fatalError("Entry not found after creation")
            }
            entry.updateUserInfo(from: info.userInfo)
            if let customPosterURL = info.customPosterURL {
                if entry.usingCustomPoster {
                    entry.posterURL = customPosterURL
                } else {
                    print(
                        "Warning: Entry \(entry.name) is not marked as using custom poster, but customPosterURL is provided."
                    )
                }
            }
        }
    }

    @Test @MainActor func inspectParentChildRelationships() throws {
        let allEntries = try dataProviderDefault.getAllModels(ofType: AnimeEntry.self)
        print("Fetched \(allEntries.count) entries.")
        for entry in allEntries {
            if let parent = entry.parentSeriesEntry {
                print("Entry: \(entry.name) has parent: \(parent.name)")
            }
        }
    }

    @Test @MainActor func testParentChildRelationshipInference() async throws {
        let dataProvider = dataProviderForPreview
        let parent = AnimeEntry.frieren
        let season = AnimeEntry(
            name: "Sousou no Frieren: Season 1",
            type: .season(seasonNumber: 1, parentSeriesID: parent.tmdbID),
            tmdbID: 400234
        )
        season.parentSeriesEntry = parent
        if parent.parentSeriesEntry == nil {
            print("Confirmed parent has no parent.")
            try dataProvider.dataHandler.newEntry(season)
            if parent.parentSeriesEntry?.parentSeriesEntry != nil {
                print("Parent has parent after adding season, inferring relationship worked.")
            }
        } else {
            print("Parent already has a parent, unexpected.")
        }
    }
}

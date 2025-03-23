//
//  LibraryStore.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation
import SwiftUI

@Observable
class LibraryStore {
    var library: [AnimeEntry] = [.init(name: "koe no katachi", mediaType: .movie)]
    private var infoFetcher: InfoFetcher = .init()
    
    /// Fetches the latest infos from tmdb for all entries and update the entries.
    func updateInfos() async throws {
        for index in library.indices {
            let basicInfo = try await infoFetcher.basicInfo(for: library[index])
            library[index].updateInfo(from: basicInfo)
        }
    }
}

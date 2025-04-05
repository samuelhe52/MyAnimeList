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
    var library: [AnimeEntry] = []
    var infoFetcher: InfoFetcher = .init()
    
    /// Fetches the latest infos from tmdb for all entries and update the entries.
    @MainActor
    func updateInfos() async throws {
        for index in library.indices {
            try await library[index].refreshInfo(fetcher: infoFetcher)
        }
    }
}

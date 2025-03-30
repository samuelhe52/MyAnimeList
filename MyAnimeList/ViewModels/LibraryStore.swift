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
    var tvAnimeLibrary: [TVSeasonEntry] = []
    var movieLibrary: [MovieEntry] = []
    
    private var infoFetcher: InfoFetcher = .init()
    
    /// Fetches the latest infos from tmdb for all entries and update the entries.
    @MainActor
    func updateInfos() async throws {
        for index in tvAnimeLibrary.indices {
            try await tvAnimeLibrary[index].refreshInfo(fetcher: infoFetcher)
        }
        for index in movieLibrary.indices {
            try await movieLibrary[index].refreshInfo(fetcher: infoFetcher)
        }
    }
}

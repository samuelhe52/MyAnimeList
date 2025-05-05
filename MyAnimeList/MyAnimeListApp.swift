//
//  MyAnimeListApp.swift
//  MyAnimeList
//
//  Created by Samuel He on 2024/12/8.
//

import SwiftUI
import SwiftData

@main
struct MyAnimeListApp: App {
    let dataProvider = DataProvider.default
    @State var libraryStore: LibraryStore = .init(dataProvider: .default)
    @AppStorage(.preferredMetadataLanguage) var language: Language = .japanese
    @AppStorage(.tmdbAPIKey) var tmdbAPIKey: String?

    var body: some Scene {
        WindowGroup {
            ZStack {
                if let tmdbAPIKey, !tmdbAPIKey.isEmpty {
                    LibraryView(store: libraryStore)
                        .onAppear { libraryStore.language = language }
                        .transition(.opacity.animation(.easeInOut(duration: 1)))
                } else {
                    TMDbAPIKeyEditor()
                        .transition(.opacity.animation(.easeInOut(duration: 1)))
                }
            }
            .globalToasts()
        }
    }
}

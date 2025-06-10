//
//  MyAnimeListApp.swift
//  MyAnimeList
//
//  Created by Samuel He on 2024/12/8.
//

import SwiftUI
import SwiftData
import DataProvider

@main
struct MyAnimeListApp: App {
    @State var libraryStore: LibraryStore = .init(dataProvider: .default)
    @State var keyStorage: TMDbAPIKeyStorage = .init()
    @AppStorage(.preferredMetadataLanguage) var language: Language = .japanese

    var body: some Scene {
        WindowGroup {
            ZStack {
                if let key = keyStorage.key, !key.isEmpty {
                    LibraryView(store: libraryStore)
                        .onAppear { libraryStore.language = language }
                        .transition(.opacity.animation(.easeInOut(duration: 1)))
                } else {
                    TMDbAPIConfigurator(keyStorage: keyStorage)
                        .transition(.opacity.animation(.easeInOut(duration: 1)))
                }
            }
            .globalToasts()
        }
    }
}

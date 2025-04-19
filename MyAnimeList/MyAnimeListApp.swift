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
    @AppStorage("PreferredMetadataLanguage") var language: Language = .japanese

    var body: some Scene {
        WindowGroup {
            LibraryView(store: libraryStore)
                .onAppear {
                    libraryStore.language = language
                }
        }
    }
}

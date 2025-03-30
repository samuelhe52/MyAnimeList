//
//  MyAnimeListApp.swift
//  MyAnimeList
//
//  Created by Samuel He on 2024/12/8.
//

import SwiftUI

@main
struct MyAnimeListApp: App {
    @State var libraryStore: LibraryStore = .init()
    
    var body: some Scene {
        WindowGroup {
            LibraryView(store: libraryStore)
        }
    }
}

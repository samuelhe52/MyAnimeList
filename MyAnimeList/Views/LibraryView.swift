//
//  LibraryView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2024/12/8.
//

import SwiftUI

struct LibraryView: View {
    var store: LibraryStore
    @State var isSearching: Bool = false
    
    var body: some View {
        Text("Hello, my library!")
        Button("Search...") {
            isSearching = true
        }.buttonStyle(.bordered)
        .sheet(isPresented: $isSearching) {
            NavigationStack {
                SearchPage()
                    .navigationTitle("Search TMDB")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

#Preview {
    @Previewable let store = LibraryStore()
    LibraryView(store: store)
}

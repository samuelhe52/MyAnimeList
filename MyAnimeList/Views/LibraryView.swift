//
//  LibraryView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2024/12/8.
//

import SwiftUI
import Kingfisher

struct LibraryView: View {
    var store: LibraryStore
    @State var isSearching: Bool = false
    @AppStorage("PreferredMetadataLanguage") var language: Language = .japanese
    
    @State var showAlert = false
    @State var cacheSizeResult: Result<UInt, KingfisherError>? = nil
    @State var selectedEntryID: Int?
    
    var body: some View {
        NavigationStack {
            if !store.library.isEmpty {
                TabView(selection: $selectedEntryID) {
                    ForEach(store.library) { entry in
                        card(entry: entry).tag(entry.tmdbID)
                    }
                }
                .tabViewStyle(.page)
            } else {
                Text("The library is empty.")
            }
            VStack{
                Button("Search...") { isSearching = true }
                HStack {
                    checkCacheButton
                    Button("Clear", role: .destructive) {
                        Task { try await store.clearLibrary() }
                    }
                }
            }
            .buttonStyle(.bordered)
            .sheet(isPresented: $isSearching) {
                NavigationStack {
                    SearchPage { result in
                        Task { try await processSearchResult(result) }
                    }
                    .navigationTitle("Search TMDB")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .animation(.smooth, value: selectedEntryID)
        .animation(.default, value: store.library)
        .padding(.vertical)
    }
    
    private var checkCacheButton: some View {
        Button("Check Cache") {
            KingfisherManager.shared.cache.calculateDiskStorageSize { result in
                DispatchQueue.main.async {
                    cacheSizeResult = result
                    showAlert = true
                }
            }
        }
        .alert(
            "Disk Cache",
            isPresented: $showAlert,
            presenting: cacheSizeResult,
            actions: { result in
                switch result {
                case .success:
                    Button("Clear") {
                        KingfisherManager.shared.cache.clearCache()
                    }
                    Button("Cancel", role: .cancel) {}
                case .failure:
                    Button("OK") { }
                }
            }, message: { result in
                switch result {
                case .success(let size):
                    Text("Size: \(Double(size) / 1024 / 1024, specifier: "%.2f") MB")
                case .failure(let error):
                    Text(error.localizedDescription)
                }
            })
    }
    
    private func card(entry: AnimeEntry) -> some View {
        AnimeEntryCard(entry: entry)
            .contextMenu {
                Button("Delete", role: .destructive) {
                    // TODO: Update selectedEntryID or use ScrollViews instead.
                    Task {
                        try await store.deleteEntry(id: entry.persistentModelID)
                    }
                }
            }
    }
    
    private func processSearchResult(_ result: SearchResult) async throws {
        isSearching = false
        try await store.newEntryFromSearchResult(result: result)
        selectedEntryID = result.tmdbID
    }
}

#Preview {
    @Previewable let store = LibraryStore(dataProvider: .forPreview)
    LibraryView(store: store)
}

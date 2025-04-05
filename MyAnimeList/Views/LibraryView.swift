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
    @State var selectedEntryID: AnimeEntry.ID = 0
    
    var body: some View {
        NavigationStack {
            if !store.library.isEmpty {
                TabView(selection: $selectedEntryID) {
                    ForEach(store.library) { entry in
                        AnimeEntryCard(entry: entry)
                            .tag(entry.id)
                    }
                }
                .tabViewStyle(.page)
            } else {
                Text("The library is empty.")
            }
            HStack {
                Button("Search...") {
                    isSearching = true
                }
                Button("Check Cache") {
                    KingfisherManager.shared.cache.calculateDiskStorageSize { result in
                        Task {
                            await MainActor.run {
                                cacheSizeResult = result
                                showAlert = true
                            }
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
            .buttonStyle(.bordered)
            .sheet(isPresented: $isSearching) {
                NavigationStack {
                    SearchPage { result in
                        store.newEntryFromSearchResult(result: result)
                        selectedEntryID = result.id
                    }
                    .navigationTitle("Search TMDB")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
}

#Preview {
    @Previewable let store = LibraryStore()
    LibraryView(store: store)
        .task {
            await store.infoFetcher.changeLanguage(.japanese)
        }
}

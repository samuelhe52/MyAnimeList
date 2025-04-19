//
//  LibraryView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2024/12/8.
//

import SwiftUI
import Kingfisher
import Combine

struct LibraryView: View {
    var store: LibraryStore
    @State private var isSearching: Bool = false
    @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape
    @AppStorage("PreferredMetadataLanguage") var language: Language = .japanese
    
    @State private var showCacheAlert = false
    @State private var showClearAllAlert = false
    @State private var cacheSizeResult: Result<UInt, KingfisherError>? = nil
    @State private var scrolledID: Int?
    
    var body: some View {
        NavigationStack {
            if !store.library.isEmpty {
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(store.library, id: \.tmdbID) { entry in
                            card(entry: entry)
                                .containerRelativeFrame(!isLandscape ? .horizontal
                                                        : .vertical)
                        }
                    }.scrollTargetLayout()
                }
                .scrollPosition(id: $scrolledID)
                .scrollTargetBehavior(.viewAligned)
            } else {
                Text("The library is empty.")
            }
            VStack{
                Button("Search...") { isSearching = true }
                HStack {
                    checkCacheButton
                    clearAllButton
                }
            }
            .buttonStyle(.bordered)
            .sheet(isPresented: $isSearching) {
                NavigationStack {
                    SearchPage(service: .init()) { result in
                        Task { try await processSearchResult(result) }
                    }
                    .navigationTitle("Search TMDB")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .onReceive(
            NotificationCenter.default
                .publisher(for: UIDevice.orientationDidChangeNotification),
            perform: { _ in
                let orientation = UIDevice.current.orientation
                isLandscape = orientation.isLandscape
            }
        )
        .animation(.default, value: store.library)
        .padding(.vertical)
//        .onChange(of: scrolledID) {
//            print(store.library[scrolledID ?? 0]?.name ?? "")
//        }
    }
    
    private var clearAllButton: some View {
        Button("Clear all",  role: .destructive) {
            showClearAllAlert = true
        }
        .alert("Clear all entries?", isPresented: $showClearAllAlert) {
            Button("Clear", role: .destructive) {
                Task { try await store.clearLibrary() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private var checkCacheButton: some View {
        Button("Check Cache") {
            KingfisherManager.shared.cache.calculateDiskStorageSize { result in
                DispatchQueue.main.async {
                    cacheSizeResult = result
                    showCacheAlert = true
                }
            }
        }
        .alert(
            "Disk Cache",
            isPresented: $showCacheAlert,
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
                    Task {
                        withAnimation {
                            scrolledID = scrollIDAfterDelete(deletedID: entry.tmdbID,
                                                             strategy: .next)
                        }
                        try await store.deleteEntry(id: entry.persistentModelID)
                    }
                }
            }
    }
    
    private func processSearchResult(_ result: SearchResult) async throws {
        isSearching = false
        try await store.newEntryFromSearchResult(result: result)
        withAnimation {
            scrolledID = result.tmdbID
        }
    }
}

extension LibraryView {
    private func scrollIDAfterDelete(deletedID: Int, strategy: ScrollAfterDeleteStrategy) -> Int? {
        guard let index = store.library.firstIndex(where: { $0.tmdbID == deletedID }) else { return nil }
        switch strategy {
        case .next:
            return index < store.library.count - 1 ?
            store.library[index + 1].tmdbID : nil
        case .previous:
            return index > 0 ?
            store.library[index - 1].tmdbID : nil
        }
    }
    
    enum ScrollAfterDeleteStrategy {
        case next
        case previous
    }
}

#Preview {
    @Previewable let store = LibraryStore(dataProvider: .default)
    LibraryView(store: store)
}

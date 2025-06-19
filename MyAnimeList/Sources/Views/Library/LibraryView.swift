//
//  LibraryView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2024/12/8.
//

import SwiftUI
import Kingfisher
import SwiftData
import Collections

struct LibraryView: View {
    var store: LibraryStore
    
    @State private var isSearching = false
    @State private var changeAPIKey = false
    @State private var showCacheAlert = false
    @State private var showClearAllAlert = false
    @State private var cacheSizeResult: Result<UInt, KingfisherError>? = nil
    @State private var scrollState = ScrollState()
    @State private var newEntriesAddedToggle = false

    @AppStorage(.preferredMetadataLanguage) var language: Language = .japanese
    
    var body: some View {
        NavigationStack {
            VStack {
                LibraryTheaterView(store: store,
                                  scrolledID: $scrollState.scrolledID)
                controls
            }
            .padding(.vertical)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .sensoryFeedback(.success, trigger: newEntriesAddedToggle)
        }
    }
    
    @ViewBuilder
    private var controls: some View {
        HStack{
            Button("Search...") { isSearching = true }
                .buttonBorderShape(.capsule)
            Menu {
                apiConfigruation
                checkDiskUsageButton
                refreshInfosButton
                deleteAllButton
            } label: {
                Image(systemName: "ellipsis").padding(.vertical, 7.5)
            }
            .labelStyle(.iconOnly)
            .buttonBorderShape(.circle)
        }
        .buttonStyle(.bordered)
        .sheet(isPresented: $isSearching) {
            NavigationStack {
                SearchPage { processResults($0) }
                .navigationTitle("Search TMDB")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .alert("Delete all entries?", isPresented: $showClearAllAlert) {
            Button("Delete", role: .destructive) {
                store.clearLibrary()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Disk Usage", isPresented: $showCacheAlert, presenting: cacheSizeResult,
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
        .sheet(isPresented: $changeAPIKey) {
            TMDbAPIConfigurator(isEditing: true)
                .presentationDetents([.medium, .large])
        }
    }
    
    private var deleteAllButton: some View {
        Button("Delete All Entries", systemImage: "trash", role: .destructive) {
            showClearAllAlert = true
        }
    }
    
    private var checkDiskUsageButton: some View {
        Button("Check Disk Usage", systemImage: "archivebox") {
            KingfisherManager.shared.cache.calculateDiskStorageSize { result in
                DispatchQueue.main.async {
                    cacheSizeResult = result
                    showCacheAlert = true
                }
            }
        }
    }
    
    private var apiConfigruation: some View {
        Button("Change API Key", systemImage: "person.badge.key") { changeAPIKey = true }
    }
    
    private var refreshInfosButton: some View {
        Button("Refresh Infos", systemImage: "arrow.clockwise") {
            store.refreshInfos()
        }
    }
    
    private func processResults(_ results: OrderedSet<SearchResult>) {
        isSearching = false
        Task {
            let success = await store.newEntryFromSearchResults(results)
            if success {
                withAnimation {
                    newEntriesAddedToggle.toggle()
                    if let id = results.first?.tmdbID {
                        scrollState.scrolledID = id
                    }
                }
            }
        }
    }
}


#Preview {
    // dataProvider could be changed to .forPreview for memory-only storage.
    // Uncomment the task below to generate template entries.
    @Previewable let store = LibraryStore(dataProvider: .default)
    LibraryView(store: store)
//        .task {
//            await withTaskGroup(of: Void.self) { group in
//                for index in 0..<50 {
//                    group.addTask {
//                        let info = AnimeEntry.template(id: index).basicInfo
//                        try? await store.newEntryFromInfo(info: info)
//                    }
//                }
//                await group.waitForAll()
//            }
//        }
}

//
//  LibraryView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2024/12/8.
//

import SwiftUI
import Kingfisher
import Combine
import AlertToast
import SwiftData

struct LibraryView: View {
    var store: LibraryStore
    @State private var isSearching: Bool = false
    @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape
    @AppStorage("PreferredMetadataLanguage") var language: Language = .japanese
    
    @State private var scrolledID: Int?
    private let scrolledIDSubject = PassthroughSubject<Int?, Never>()
    private let writer: DebouncedIntUserDefaultsWriter
    
    init(store: LibraryStore) {
        self.store = store
        let persistedScrollPosition = UserDefaults.standard.integer(forKey: "persistedScrolledID")
        self._scrolledID = .init(initialValue: persistedScrollPosition)
        self.writer = DebouncedIntUserDefaultsWriter(publisher: scrolledIDSubject.eraseToAnyPublisher(),
                                                forKey: "persistedScrolledID")
    }
    
    var body: some View {
        NavigationStack {
            library
            controls
        }
        .animation(.default, value: store.library)
        .onReceive(
            NotificationCenter.default
                .publisher(for: UIDevice.orientationDidChangeNotification),
            perform: { _ in
                let orientation = UIDevice.current.orientation
                isLandscape = orientation.isLandscape
            }
        )
        .padding(.vertical)
        .onChange(of: scrolledID) {
            scrolledIDSubject.send(scrolledID)
        }
    }
    
    @ViewBuilder
    private var library: some View {
        if !store.library.isEmpty {
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(store.library, id: \.tmdbID) { entry in
                        card(entry: entry)
                    }
                }.scrollTargetLayout()
            }
            .scrollPosition(id: $scrolledID)
            .scrollTargetBehavior(.viewAligned)
        } else {
            Text("The library is empty.")
        }
    }
    
    @State private var showCacheAlert = false
    @State private var showClearAllAlert = false
    @State private var cacheSizeResult: Result<UInt, KingfisherError>? = nil
    
    @ViewBuilder
    private var controls: some View {
        HStack{
            Button("Search...") { isSearching = true }
            Menu {
                checkCacheButton
                refreshInfosButton
                clearAllButton
            } label: {
                Image(systemName: "ellipsis.circle")
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
        .alert("Clear all entries?", isPresented: $showClearAllAlert) {
            Button("Clear", role: .destructive) {
                Task { try await store.clearLibrary() }
            }
            Button("Cancel", role: .cancel) {}
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
    
    private var clearAllButton: some View {
        Button("Clear all", systemImage: "trash", role: .destructive) {
            showClearAllAlert = true
        }
    }
    
    private var checkCacheButton: some View {
        Button("Check Cache", systemImage: "archivebox") {
            KingfisherManager.shared.cache.calculateDiskStorageSize { result in
                DispatchQueue.main.async {
                    cacheSizeResult = result
                    showCacheAlert = true
                }
            }
        }
    }
    
    private var refreshInfosButton: some View {
        Button("Refresh Infos", systemImage: "arrow.clockwise") {
            Task { try await store.refreshInfos() }
        }
    }
        
    private func card(entry: AnimeEntry) -> some View {
        AnimeEntryCard(entry: entry, onDelete: {
            Task { try await store.deleteEntry(withID: entry.id) }
        })
            .transition(
                .asymmetric(insertion: .opacity, removal: .move(edge: .top).combined(with: .opacity))
                .animation(.default)
            )
            .containerRelativeFrame(!isLandscape ? .horizontal
                                    : .vertical)

    }
    
    private func processSearchResult(_ result: SearchResult) async throws {
        isSearching = false
        try await store.newEntryFromSearchResult(result: result)
        withAnimation {
            scrolledID = result.tmdbID
        }
    }
}

class DebouncedIntUserDefaultsWriter {
    private var cancellable: AnyCancellable?
    
    init<P: Publisher>(publisher: P, forKey key: String, delay: TimeInterval = 0.5) where P.Output == Int?, P.Failure == Never {
        let queue = DispatchQueue(label: "com.samuelhe.MyAnimeList.userdefaults.intwriter", qos: .background)
        
        self.cancellable = publisher
            .debounce(for: .seconds(delay), scheduler: queue)
            .sink { value in
                UserDefaults.standard.set(value, forKey: key)
            }
    }
}

// This is where we place debug-specific code.
extension LibraryView {
    private func mockDelete(withID id: PersistentIdentifier) {
        store.mockDeleteEntry(withId: id)
    }
}

#Preview {
    @Previewable let store = LibraryStore(dataProvider: .default)
    LibraryView(store: store)
}

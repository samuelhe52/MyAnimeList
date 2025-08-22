//
//  LibraryGridView.swift
//  MyAnimeList
//
//  Created by Samuel He on 7/27/25.
//

import SwiftUI
import DataProvider

struct LibraryGridView: View {
    let store: LibraryStore
    @Environment(\.dataHandler) var dataHandler
    @Environment(\.toggleFavorite) var toggleFavorite
    
    @State private var deletingEntry: AnimeEntry?
    @State private var isDeletingEntry: Bool = false
    @State private var favoritedTrigger: Bool = false
    @State private var editingEntry: AnimeEntry?
    @State private var switchingPosterForEntry: AnimeEntry?
    @State private var showPasteAlert: Bool = false
    @State private var pasteAction: (() -> Void)?
    @State private var triggerScroll: Bool = false
    @Binding var scrolledID: Int?
    @Binding var highlightedEntryID: Int?
    
    private func showHighlightBinding(for entry: AnimeEntry) -> Binding<Bool> {
        Binding(get: {
            entry.tmdbID == highlightedEntryID
        }, set: {
            if !$0 {
                highlightedEntryID = nil
            }
        })
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView{
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))]) {
                    ForEach(store.libraryOnDisplay, id: \.tmdbID) { entry in
                        LibraryGridItem(entry: entry)
                            .highlightEffect(showHighlight: showHighlightBinding(for: entry), delay: 0.2)
                            .contextMenu(menuItems: {
                                contextMenu(for: entry)
                                    .onAppear { scrolledID = entry.tmdbID }
                            })
                            .onTapGesture { scrolledID = entry.tmdbID }
                            .onTapGesture(count: 2) {
                                editingEntry = entry
                                scrolledID = entry.tmdbID
                            }
                    }
                }
                .onChange(of: scrolledID) {
                    if let scrolledID {
                        withAnimation {
                            proxy.scrollTo(scrolledID)
                        }
                    }
                }
                .onAppear {
                    // Prevent the problem of programmatic scrolling doesn't work when images aren't loaded yet.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let scrolledID {
                            withAnimation {
                                proxy.scrollTo(scrolledID, anchor: .center)
                            }
                        }
                    }
                }
            }
            .animation(.spring, value: store.sortReversed)
            .animation(.spring, value: store.sortStrategy)
            .animation(.spring, value: store.filters)
            .padding(.horizontal)
            .alert("Delete Anime?",
                   isPresented: $isDeletingEntry,
                   presenting: deletingEntry,
                   actions: { entry in
                Button("Delete", role: .destructive) { store.deleteEntry(entry) }
                Button("Cancel", role: .cancel) {}
            })
            .alert("Paste Info?",
                   isPresented: $showPasteAlert,
                   presenting: pasteAction,
                   actions: { action in
                Button("Paste", role: .destructive, action: action)
                Button("Cancel", role: .cancel) {}
            }, message: { _ in
                Text("This anime already has edits. Pasting will overwrite current info.")
            })
            .sheet(item: $switchingPosterForEntry) { entry in
                NavigationStack {
                    PosterSelectionView(entry: entry)
                        .navigationTitle("Pick a poster")
                }
            }
            .sheet(item: $editingEntry) { entry in
                NavigationStack {
                    AnimeEntryEditor(entry: entry)
                }
            }
        }
    }
    
    @ViewBuilder
    private func contextMenu(for entry: AnimeEntry) -> some View {
        deleteButton(for: entry)
        Button("Switch Poster", systemImage: "photo") {
            switchingPosterForEntry = entry
        }
        Button("Poster URL", systemImage: "document.on.clipboard") {
            UIPasteboard.general.string = entry.posterURL?.absoluteString ?? ""
            ToastCenter.global.copied = true
        }
        EntryFavoriteButton(favorited: entry.favorite) {
            toggleFavorite(entry)
        }
        Button("Copy Info", systemImage: "doc.on.doc") {
            let userInfo = UserEntryInfo(for: entry)
            userInfo.copyToPasteboard()
            ToastCenter.global.copied = true
        }
        Button("Paste Info", systemImage: "doc.on.clipboard") {
            pasteInfoAction(for: entry)
        }
        .disabled(!UIPasteboard.general.contains(pasteboardTypes: [UserEntryInfo.pasteboardUTType.identifier]))
        editButton(for: entry)
    }
    
    @ViewBuilder
    private func deleteButton(for entry: AnimeEntry) -> some View {
        Button("Delete", systemImage: "trash") {
            if let index = store.libraryOnDisplay.firstIndex(of: entry) {
                if index != 0 {
                    scrolledID = store.libraryOnDisplay[index - 1].tmdbID
                } else {
                    scrolledID = store.libraryOnDisplay.last?.tmdbID
                }
            }
            deletingEntry = entry
            isDeletingEntry = true
        }
        .tint(.red)
    }
    
    @ViewBuilder
    private func editButton(for entry: AnimeEntry) -> some View {
        Button("Edit", systemImage: "pencil") {
            editingEntry = entry
        }
    }
    
    private func pasteInfoAction(for entry: AnimeEntry) {
        if let pasted = UserEntryInfo.fromPasteboard() {
            let paste = {
                entry.updateUserInfo(from: pasted)
                ToastCenter.global.pasted = true
            }
            if UserEntryInfo(for: entry).isEmpty {
                paste()
            } else {
                showPasteAlert = true
                pasteAction = paste
            }
        } else {
            ToastCenter.global.completionState = .init(state: .failed, messageResource: "No info found on pasteboard.")
        }
    }
}

fileprivate struct LibraryGridItem: View {
    var entry: AnimeEntry
    
    var body: some View {
        VStack {
            KFImageView(url: entry.posterURL, diskCacheExpiration: .longTerm)
                .clipShape(.proportionalRounded(cornerFraction: 0.05))
                .aspectRatio(contentMode: .fit)
            Text(entry.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

#Preview {
    LibraryGridView(store: LibraryStore(dataProvider: .forPreview),
                    scrolledID: .constant(nil),
                    highlightedEntryID: .constant(nil))
        .onAppear {
            DataProvider.forPreview.generateEntriesForPreview()
        }
        .environment(\.dataHandler, DataProvider.forPreview.dataHandler)
}

//
//  LibraryListView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/6/29.
//

import DataProvider
import SwiftUI

struct LibraryListView: View {
    let store: LibraryStore
    @Environment(\.dataHandler) var dataHandler
    @Environment(\.toggleFavorite) var toggleFavorite

    @State private var deletingEntry: AnimeEntry?
    @State private var isDeletingEntry: Bool = false
    @State private var editingEntry: AnimeEntry?
    @State private var switchingPosterForEntry: AnimeEntry?
    @State private var showPasteAlert: Bool = false
    @State private var pasteAction: (() -> Void)?
    @Binding var scrolledID: Int?
    @Binding var highlightedEntryID: Int?

    var body: some View {
        ScrollViewReader { proxy in
            List(store.libraryOnDisplay, id: \.tmdbID) { entry in
                AnimeEntryListRow(entry: entry)
                    .highlightEffect(showHighlight: showHighlightBinding(for: entry), delay: 0.2)
                    .onTapGesture { scrolledID = entry.tmdbID }
                    .contextMenu(
                        menuItems: { contextMenu(for: entry) },
                        preview: {
                            EntryPreview(entry: entry)
                                .onAppear { scrolledID = entry.tmdbID }
                        }
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        deleteButton(for: entry)
                    }
                    .swipeActions(edge: .leading) {
                        editButton(for: entry)
                            .tint(.blue)
                    }
                    .onTapGesture(count: 2) { editingEntry = entry }
            }
            .animation(.default, value: store.sortReversed)
            .animation(.default, value: store.sortStrategy)
            .animation(.default, value: store.filters)
            .alert(
                "Delete Anime?",
                isPresented: $isDeletingEntry,
                presenting: deletingEntry,
                actions: { entry in
                    Button("Delete", role: .destructive) { store.deleteEntry(entry) }
                    Button("Cancel", role: .cancel) {}
                }
            )
            .alert(
                "Paste Info?",
                isPresented: $showPasteAlert,
                presenting: pasteAction,
                actions: { action in
                    Button("Paste", role: .destructive, action: action)
                    Button("Cancel", role: .cancel) {}
                },
                message: { _ in
                    Text("This anime already has edits. Pasting will overwrite current info.")
                }
            )
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
            .onChange(of: scrolledID, initial: true) {
                if let scrolledID {
                    proxy.scrollTo(scrolledID)
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
            entry.userInfo.copyToPasteboard()
            ToastCenter.global.copied = true
        }
        Button("Paste Info", systemImage: "doc.on.clipboard") {
            pasteInfoAction(for: entry)
        }
        .disabled(
            !UIPasteboard.general.contains(pasteboardTypes: [
                UserEntryInfo.pasteboardUTType.identifier
            ]))
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

    private func showHighlightBinding(for entry: AnimeEntry) -> Binding<Bool> {
        Binding(
            get: { entry.tmdbID == highlightedEntryID },
            set: { if !$0 { highlightedEntryID = nil } })
    }

    private func pasteInfoAction(for entry: AnimeEntry) {
        if let pasted = UserEntryInfo.fromPasteboard() {
            let paste = {
                entry.updateUserInfo(from: pasted)
                ToastCenter.global.pasted = true
            }
            if entry.userInfo.isEmpty {
                paste()
            } else {
                showPasteAlert = true
                pasteAction = paste
            }
        } else {
            ToastCenter.global.completionState = .init(
                state: .failed, messageResource: "No info found on pasteboard.")
        }
    }
}

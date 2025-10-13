//
//  LibraryEntryInteractionState.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/10/13.
//

import DataProvider
import Observation
import SwiftUI
import UIKit

@Observable
@MainActor
final class LibraryEntryInteractionState {
    var deletingEntry: AnimeEntry?
    var isDeletingEntry: Bool = false
    var editingEntry: AnimeEntry?
    var switchingPosterForEntry: AnimeEntry?
    var showPasteAlert: Bool = false
    var pasteAction: (() -> Void)?

    func setScrolledIDBeforeDeletion(for entry: AnimeEntry, in store: LibraryStore, scrolledID: Binding<Int?>) {
        if let index = store.libraryOnDisplay.firstIndex(of: entry) {
            if index != 0 {
                scrolledID.wrappedValue = store.libraryOnDisplay[index - 1].tmdbID
            } else {
                scrolledID.wrappedValue = store.libraryOnDisplay.last?.tmdbID
            }
        }
    }

    func prepareDeletion(for entry: AnimeEntry, store: LibraryStore, scrolledID: Binding<Int?>) {
        setScrolledIDBeforeDeletion(for: entry, in: store, scrolledID: scrolledID)
        deletingEntry = entry
        isDeletingEntry = true
    }

    func setEditingEntry(_ entry: AnimeEntry) {
        editingEntry = entry
    }

    func pasteInfo(for entry: AnimeEntry) {
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
                state: .failed,
                messageResource: "No info found on pasteboard."
            )
        }
    }

    func highlightBinding(for entry: AnimeEntry, highlightedEntryID: Binding<Int?>) -> Binding<Bool> {
        Binding(
            get: { highlightedEntryID.wrappedValue == entry.tmdbID },
            set: { if !$0 { highlightedEntryID.wrappedValue = nil } }
        )
    }
}

extension LibraryEntryInteractionState {
    @ViewBuilder
    func contextMenu(
        for entry: AnimeEntry,
        store: LibraryStore,
        scrolledID: Binding<Int?>,
        toggleFavorite: @escaping (AnimeEntry) -> Void
    ) -> some View {
        Button("Delete", systemImage: "trash", role: .destructive) {
            self.prepareDeletion(for: entry, store: store, scrolledID: scrolledID)
        }
        Button("Switch Poster", systemImage: "photo") {
            self.switchingPosterForEntry = entry
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
            self.pasteInfo(for: entry)
        }
        .disabled(
            !UIPasteboard.general.contains(
                pasteboardTypes: [UserEntryInfo.pasteboardUTType.identifier]
            )
        )
        Button("Edit", systemImage: "pencil") {
            self.editingEntry = entry
        }
    }
}

extension View {
    func libraryEntryInteractionOverlays(
        state: LibraryEntryInteractionState,
        store: LibraryStore
    ) -> some View {
        self
            .alert(
                "Delete Anime?",
                isPresented: Binding(
                    get: { state.isDeletingEntry },
                    set: { state.isDeletingEntry = $0 }
                ),
                presenting: state.deletingEntry
            ) { entry in
                Button("Delete", role: .destructive) { store.deleteEntry(entry) }
                Button("Cancel", role: .cancel) {}
            }
            .alert(
                "Paste Info?",
                isPresented: Binding(
                    get: { state.showPasteAlert },
                    set: { state.showPasteAlert = $0 }
                ),
                presenting: state.pasteAction
            ) { action in
                Button("Paste", role: .destructive, action: action)
                Button("Cancel", role: .cancel) {}
            } message: { _ in
                Text("This anime already has edits. Pasting will overwrite current info.")
            }
            .sheet(
                item: Binding(
                    get: { state.switchingPosterForEntry },
                    set: { state.switchingPosterForEntry = $0 }
                )
            ) { entry in
                NavigationStack {
                    PosterSelectionView(entry: entry)
                        .navigationTitle("Pick a poster")
                }
            }
            .sheet(
                item: Binding(
                    get: { state.editingEntry },
                    set: { state.editingEntry = $0 }
                )
            ) { entry in
                NavigationStack {
                    AnimeEntryEditor(entry: entry)
                }
            }
    }
}

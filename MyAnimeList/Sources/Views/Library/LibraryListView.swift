//
//  LibraryListView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/6/29.
//

import SwiftUI
import DataProvider

struct LibraryListView: View {
    let store: LibraryStore
    @Environment(\.dataHandler) var dataHandler
    
    @State private var deletingEntry: AnimeEntry?
    @State private var isDeletingEntry: Bool = false
    @State private var favoritedTrigger: Bool = false
    @State private var editingEntry: AnimeEntry?
    @State private var switchingPosterForEntry: AnimeEntry?
    @State private var showPasteAlert: Bool = false
    @State private var pasteAction: (() -> Void)?
    @Binding var scrolledID: Int?
    @Binding var highlightedEntryID: Int?
        
    var body: some View {
        ScrollViewReader { proxy in
            List(store.libraryOnDisplay, id: \.tmdbID) { entry in
                HStack {
                    PosterView(url: entry.posterURL, diskCacheExpiration: .longTerm)
                        .scaledToFit()
                        .clipShape(.rect(cornerRadius: 6))
                        .frame(width: 80, height: 120)
                    info(entry: entry)
                }
                .highlightEffect(showHighlight: showHighlightBinding(for: entry), delay: 0.2)
                .onTapGesture { scrolledID = entry.tmdbID }
                .contextMenu(menuItems: { contextMenu(for: entry) }, preview: {
                    PosterView(url: entry.posterURL, diskCacheExpiration: .longTerm)
                        .scaledToFit()
                        .overlay(alignment: .bottomTrailing) {
                            AnimeTypeIndicator(type: entry.type)
                                .offset(x: -3, y: -3)
                                .font(.footnote)
                        }
                        .onAppear { scrolledID = entry.tmdbID }
                })
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
            .navigationTitle("\(store.libraryOnDisplay.count) Anime")
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
            .onChange(of: scrolledID, initial: true) {
                if let scrolledID {
                    proxy.scrollTo(scrolledID)
                }
            }
            .sensoryFeedback(.impact, trigger: favoritedTrigger)
        }
    }
    
    @ViewBuilder
    private func info(entry: AnimeEntry) -> some View {
        VStack(alignment: .leading) {
            Text(entry.displayName)
                .bold()
                .lineLimit(1)
            HStack {
                if entry.isSeason {
                    Text(entry.name)
                }
                if let date = entry.onAirDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                }
            }
            .font(.caption)
            .padding(.bottom, 1)
            Text(entry.displayOverview ?? "No overview available")
                .font(.caption2)
                .foregroundStyle(.gray)
                .lineLimit(5)
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
            dataHandler?.toggleFavorite(entry: entry)
            favoritedTrigger.toggle()
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
    
    private func showHighlightBinding(for entry: AnimeEntry) -> Binding<Bool> {
        Binding(get: {
            entry.tmdbID == highlightedEntryID
        }, set: {
            if !$0 {
                highlightedEntryID = nil
            }
        })
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
            ToastCenter.global.completionState = .init(state: .failed, message: "No info found on pasteboard.")
        }
    }
}

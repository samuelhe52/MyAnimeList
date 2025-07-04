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
    
    @State var deletingEntry: AnimeEntry?
    @State var isDeletingEntry: Bool = false
    @State var editingEntry: AnimeEntry?
    @State var switchingPosterForEntry: AnimeEntry?
    
    var body: some View {
        List(store.libraryOnDisplay) { entry in
            HStack {
                PosterView(url: entry.posterURL, diskCacheExpiration: .longTerm)
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: 6))
                    .frame(width: 80, height: 120)
                info(entry: entry)
            }
            .contextMenu(menuItems: { contextMenu(for: entry) }, preview: {
                PosterView(url: entry.posterURL, diskCacheExpiration: .longTerm)
                    .scaledToFit()
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
        editButton(for: entry)
    }
    
    @ViewBuilder
    private func deleteButton(for entry: AnimeEntry) -> some View {
        Button("Delete", systemImage: "trash", role: .destructive) {
            deletingEntry = entry
            isDeletingEntry = true
        }
    }
    
    @ViewBuilder
    private func editButton(for entry: AnimeEntry) -> some View {
        Button("Edit", systemImage: "pencil") {
            editingEntry = entry
        }
    }
}

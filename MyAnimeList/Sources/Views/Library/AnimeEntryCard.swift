//
//  AnimeEntryCard.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/23.
//

import SwiftUI
import DataProvider
import Kingfisher
import AlertToast
import os

fileprivate let logger = Logger(subsystem: .bundleIdentifier, category: "AnimeEntryCard")

struct AnimeEntryCard: View {
    var entry: AnimeEntry
    var delete: () -> Void
    @State private var triggerDeleteHaptic: Bool = false
    @State private var showDeleteToast: Bool = false
    @State private var imageLoaded: Bool = false
    @State private var showPosterSwitchingView = false
    var imageMissing: Bool { entry.posterURL == nil }
    
    init(entry: AnimeEntry, onDelete delete: @escaping () -> Void) {
        self.entry = entry
        self.delete = delete
    }
    
    var body: some View {
        PosterView(url: entry.posterURL, diskCacheExpiration: .days(90), imageLoaded: $imageLoaded)
            .scaledToFit()
            .clipShape(.rect(cornerRadius: 10))
            .overlay(alignment: .bottomTrailing) {
                AnimeTypeIndicator(type: entry.type)
                    .opacity(imageLoaded ? 1 : 0)
            }
            .padding()
            .onTapGesture {
                showDeleteToast = false
            }
            .toast(isPresenting: $showDeleteToast, duration: 3, alert: {
                AlertToast(displayMode: .alert, type: .regular,
                           titleResource: "Delete Entry?",
                           subTitleResource: "Tap me to confirm.")
            }, onTap: {
                delete()
                triggerDeleteHaptic.toggle()
            })
            .contextMenu {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    showDeleteToast = true
                }
                Button {
                    showPosterSwitchingView = true
                } label: {
                    Label("Switch Poster", systemImage: "photo")
                }
                Button("Poster URL", systemImage: "document.on.clipboard") {
                    UIPasteboard.general.string = entry.posterURL?.absoluteString ?? ""
                    ToastCenter.global.copied = true
                }
            }
            .sensoryFeedback(.success, trigger: triggerDeleteHaptic)
            .sheet(isPresented: $showPosterSwitchingView) {
                NavigationStack {
                    PosterSelectionView(entry: entry)
                }
            }
    }
}

struct AnimeTypeIndicator: View {
    var type: AnimeType
    
    var description: LocalizedStringKey {
        switch type {
        case .movie: return "Movie"
        case .series: return "TV Series"
        case .season(let seasonNumber, _): return "Season \(seasonNumber)"
        }
    }
    
    var body: some View {
        Text(description)
            .font(.footnote)
            .padding(5)
            .background(in: .buttonBorder)
            .backgroundStyle(.regularMaterial)
    }
}

#Preview {
    AnimeEntryCard(entry: .template()) {}
}

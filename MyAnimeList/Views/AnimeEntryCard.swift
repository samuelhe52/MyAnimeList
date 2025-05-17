//
//  AnimeEntryCard.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/23.
//

import SwiftUI
import Kingfisher
import AlertToast
import os

fileprivate let logger = Logger(subsystem: .bundleIdentifier, category: "AnimeEntryCard")

struct AnimeEntryCard: View {
    var entry: AnimeEntry
    var delete: () -> Void
    @State private var triggerDeleteHaptic: Bool = false
    @State private var showDeleteToast: Bool = false
    @State private var posterImage: UIImage? = nil
    var imageMissing: Bool { entry.posterURL == nil }
    
    init(entry: AnimeEntry, onDelete delete: @escaping () -> Void) {
        self.entry = entry
        self.delete = delete
    }
    
    var body: some View {
        image
            .scaledToFit()
            .overlay(alignment: .bottomTrailing) {
                AnimeTypeIndicator(type: entry.type)
                    .opacity( posterImage == nil ? 0 : 1)
            }
            .padding()
            .onTapGesture {
                showDeleteToast = false
            }
            .toast(isPresenting: $showDeleteToast, duration: 3, alert: {
                AlertToast(displayMode: .alert, type: .regular,
                           title: "Delete Entry?",
                           subTitle: "Tap me to confirm.")
            }, onTap: {
                delete()
                triggerDeleteHaptic.toggle()
            })
            .contextMenu {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    showDeleteToast = true
                }
                if entry.isSeason {
                    Button {
                        Task { try await entry.switchPoster(language: .japanese) }
                    } label: {
                        Label(entry.useSeriesPoster ? "Use Season Poster" : "Use Series Poster", systemImage: "photo")
                    }
                }
                Button("Poster URL", systemImage: "document.on.clipboard") {
                    UIPasteboard.general.string = entry.posterURL?.absoluteString ?? ""
                    ToastCenter.global.copied = true
                }
            }
            .onChange(of: entry.posterURL, initial: true) {
                Task { await loadImage() }
            }
            .sensoryFeedback(.success, trigger: triggerDeleteHaptic)
    }
    
    @ViewBuilder
    private var image: some View {
        if !imageMissing {
            if let posterImage {
                Image(uiImage: posterImage)
                    .resizable()
                    .clipShape(.rect(cornerRadius: 10))
            } else {
                ProgressView()
            }
        } else {
            Image("missing_image_resource")
        }
    }
    
    private func loadImage() async {
        let kfRetrieveOptions: KingfisherOptionsInfo = [
            .cacheOriginalImage,
            .diskCacheExpiration(.days(90)),
            .onFailureImage(UIImage(named: "missing_image_resource"))
        ]
        
        if let url = entry.posterURL {
            do {
                let result = try await KingfisherManager.shared
                    .retrieveImage(with: url, options: kfRetrieveOptions)
                withAnimation {
                    posterImage = result.image
                }
            } catch {
                logger.warning("Error loading image: \(error)")
            }
        }
    }
}

struct AnimeTypeIndicator: View {
    var type: AnimeType
    var description: String {
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

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

let logger = Logger(subsystem: "MyAnimeList", category: "AnimeEntryCard")

struct AnimeEntryCard: View {
    var entry: AnimeEntry
    @State private var posterImage: UIImage? = nil
    @State private var imageMissing: Bool = false
    
    var body: some View {
        image
            .scaledToFit()
            .padding()
            .task { await loadImage() }
            .onChange(of: entry.posterURL) {
                Task { await loadImage() }
            }
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
        } else {
            imageMissing = true
        }
    }
}

#Preview {
    AnimeEntryCard(entry: .template())
}

//
//  PosterPreview.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/12/17.
//

import SwiftUI
import os

fileprivate let logger = Logger(subsystem: .bundleIdentifier, category: "PosterPreview")

struct PosterPreview: View {
    let previewPoster: Poster
    let fetcher = InfoFetcher()
    let updatePoster: (URL?) -> Void
    @State var previewPosterURL: URL? = nil

    var body: some View {
        VStack {
            Text("\(previewPoster.metadata.width) x \(previewPoster.metadata.height)")
                .font(.caption)
                .foregroundStyle(.gray)
            KFImageView(url: previewPosterURL, diskCacheExpiration: .shortTerm)
                .aspectRatio(contentMode: .fit)
            Button("Use this poster") {
                updatePoster(previewPosterURL)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .task {
            previewPosterURL = await fetchPreviewURL()
        }
    }

    private func fetchPreviewURL() async -> URL? {
        do {
            let path = previewPoster.metadata.filePath
            return
                try await fetcher
                .tmdbClient
                .imagesConfiguration
                .posterURL(for: path)
        } catch {
            logger.error("Error fetching preview poster image: \(error.localizedDescription)")
        }
        return nil
    }
}

//
//  PosterSelectionView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/6/12.
//

import SwiftUI
import DataProvider
import Kingfisher
import TMDb
import os

fileprivate let logger = Logger(subsystem: .bundleIdentifier, category: "PosterSelectionView")

typealias Poster = ImageURLWithMetadata

struct PosterSelectionView: View {
    var entry: AnimeEntry
    let fetcher = InfoFetcher()
    @State var availablePosters: [Poster] = []
    @State var seriesPosters: [Poster] = []
    @State var previewPoster: Poster?
    @State var useSeriesPoster: Bool = false
    @Environment(\.createDataHandler) var createDataHandler
    @Environment(\.dismiss) var dismiss
    @Namespace var preview
    
    let idealWidth = 200
    
    var body: some View {
        VStack {
            if entry.isSeason {
                Picker("", selection: $useSeriesPoster) {
                    Text("Season").tag(false)
                    Text("Series").tag(true)
                }
                .pickerStyle(.segmented)
            }
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 200))]) {
                    ForEach(useSeriesPoster ? seriesPosters : availablePosters, id: \.url) { poster in
                        posterWithInfo(poster: poster)
                            .onTapGesture {
                                previewPoster = poster
                            }
                    }
                }
            }.animation(.default, value: useSeriesPoster)
        }
        .fullScreenCover(item: $previewPoster) { poster in
            PosterPreview(previewPoster: poster, updatePoster: { url in
                Task {
                    let handler = await createDataHandler()
                    try await handler?.updateEntry(id: entry.id) { entry in
                        entry.posterURL = url
                    }
                    dismiss()
                }
            })
                .navigationTransition(.zoom(sourceID: poster.metadata.filePath,
                                            in: preview))
        }
        .padding()
        .onChange(of: useSeriesPoster) {
            Task {
                if let tmdbID = entry.parentSeriesID,
                useSeriesPoster {
                    seriesPosters = try await fetcher.postersForSeries(seriesID: tmdbID,
                                                                       idealWidth: idealWidth)
                    .filteredAndSorted
                }
            }
        }
        .task {
            if availablePosters.isEmpty {
                await fetchImages()
            }
        }
    }
    
    @ViewBuilder
    private func posterWithInfo(poster: Poster) -> some View {
        let width = poster.metadata.width
        let height = poster.metadata.height
        VStack {
            PosterView(url: poster.url, diskCacheExpiration: .seconds(180))
                .aspectRatio(contentMode: .fit)
            Text("\(width) x \(height)")
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .matchedTransitionSource(id: poster.metadata.filePath, in: preview)
    }
    
    private func fetchImages() async {
        do {
            var posters: [Poster]
            switch entry.type {
            case .movie:
                posters = try await fetcher.postersForMovie(for: entry.tmdbID, idealWidth: idealWidth)
            case .series:
                posters = try await fetcher.postersForSeries(seriesID: entry.tmdbID, idealWidth: idealWidth)
            case let .season(seasonNumber, parentSeriesID):
                posters = try await fetcher.postersForSeason(forSeason: seasonNumber,
                                                                         inParentSeries: parentSeriesID,
                                                                         idealWidth: idealWidth)
            }
            availablePosters = posters.filteredAndSorted
        } catch {
            logger.error("Error fetching available posters: \(error.localizedDescription)")
        }
    }
}

struct PosterPreview: View {
    let previewPoster: Poster
    let fetcher = InfoFetcher()
    let updatePoster: (URL?) -> Void
    @State var previewPosterURL: URL? = nil
    
    var body: some View {
        VStack {
            PosterView(url: previewPosterURL, diskCacheExpiration: .seconds(3600))
                .aspectRatio(contentMode: .fit)
            Button("Use this poster") {
                updatePoster(previewPosterURL)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .task {
            previewPosterURL = await fetchPreviewImage()
        }
    }
    
    private func fetchPreviewImage() async -> URL? {
        do {
            let path = previewPoster.metadata.filePath
            return try await fetcher
                .tmdbClient
                .imagesConfiguration
                .posterURL(for: path)
        } catch {
            logger.error("Error fetching preview poster image: \(error.localizedDescription)")
        }
        return nil
    }
}

extension Array where Element == Poster {
    var filteredAndSorted: [Poster] {
        self
            .filter { $0.metadata.languageCode == Language.japanese.rawValue }
            .sorted { $0.metadata.width > $1.metadata.width }
    }
}

#Preview {
    NavigationStack {
        PosterSelectionView(entry: .init(name: "Frieren", type: .series, tmdbID: 209867))
    }
}

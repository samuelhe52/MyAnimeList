//
//  PosterSelectionView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/6/12.
//

import DataProvider
import Kingfisher
import SwiftUI
import TMDb
import os

fileprivate let logger = Logger(subsystem: .bundleIdentifier, category: "PosterSelectionView")

typealias Poster = ImageURLWithMetadata

struct PosterSelectionView: View {
    let tmdbID: Int
    let type: AnimeType
    let fetcher: InfoFetcher
    let onPosterSelected: (URL) -> Void
    @State private var imageLoadState: ImageLoadState = .loading

    init(tmdbID: Int, type: AnimeType, infoFetcher: InfoFetcher = .init(), onPosterSelected: @escaping (URL) -> Void) {
        self.tmdbID = tmdbID
        self.type = type
        self.fetcher = infoFetcher
        self.onPosterSelected = onPosterSelected
    }

    @State var availablePosters: [Poster] = []
    @State var seriesPosters: [Poster] = []
    @State var previewPoster: Poster?
    @State var useSeriesPoster: Bool = false
    @Environment(\.dismiss) var dismiss
    @Namespace var preview

    private var currentPosters: [Poster] {
        useSeriesPoster ? seriesPosters : availablePosters
    }

    @MainActor
    private struct Constants {
        static let gridItemMinSize: CGFloat = 100
        static let gridItemMaxSize: CGFloat = 200
        static let gridItemVerticalSpacing: CGFloat = 12
        static let gridItemHorizontalSpacing: CGFloat = 12
        static let idealWidth: Int = 200
        static let pickerPadding: CGFloat = 5
        static let posterCornerRadius: CGFloat = 5
        static let cacheExpiration: StorageExpiration = .transient
    }

    var body: some View {
        VStack {
            if case .season = type {
                Picker(selection: $useSeriesPoster) {
                    Text("Season").tag(false)
                    Text("TV Series").tag(true)
                } label: {
                }
                .pickerStyle(.segmented)
                .padding(.bottom, Constants.pickerPadding)
            }
            switch imageLoadState {
            case .loading:
                ProgressView()
            case .loaded:
                posterGrid
            case .empty:
                ContentUnavailableView(
                    "No Posters Available",
                    systemImage: "photo.on.rectangle",
                    description: Text("TMDb did not return posters for this selection yet.")
                )
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            case .error(let error):
                Text("Error loading posters: \(error.localizedDescription)")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.red)
            }
        }
        .animation(.default.delay(0.5), value: useSeriesPoster)
        .animation(.default, value: availablePosters)
        .animation(.default, value: seriesPosters)
        .padding(.horizontal)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .fullScreenCover(item: $previewPoster) { poster in
            PosterPreview(
                previewPoster: poster,
                updatePoster: { url in
                    if let url {
                        onPosterSelected(url)
                    }
                    dismiss()
                }
            )
            .navigationTransition(
                .zoom(
                    sourceID: poster.metadata.filePath,
                    in: preview))
        }
        .onChange(of: useSeriesPoster, initial: false) { _, newValue in
            guard case .season = type else { return }
            Task {
                if newValue {
                    await fetchSeriesPostersIfNeeded()
                } else {
                    await ensurePrimaryPostersLoadedIfNeeded()
                }
            }
        }
        .task {
            await ensurePrimaryPostersLoadedIfNeeded()
        }
    }

    @ViewBuilder
    private var posterGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(
                            minimum: Constants.gridItemMinSize,
                            maximum: Constants.gridItemMaxSize),
                        spacing: Constants.gridItemHorizontalSpacing)
                ],
                spacing: Constants.gridItemVerticalSpacing
            ) {
                ForEach(currentPosters, id: \.url) { poster in
                    posterWithInfo(poster: poster)
                        .transition(.opacity)
                        .onTapGesture {
                            previewPoster = poster
                        }
                }
            }
        }
    }

    @ViewBuilder
    private func posterWithInfo(poster: Poster) -> some View {
        let width = poster.metadata.width
        let height = poster.metadata.height
        VStack {
            KFImageView(url: poster.url, targetWidth: 300, diskCacheExpiration: Constants.cacheExpiration)
                .clipShape(RoundedRectangle(cornerRadius: Constants.posterCornerRadius))
                .aspectRatio(contentMode: .fit)
            Text("\(width) x \(height)")
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .matchedTransitionSource(id: poster.metadata.filePath, in: preview)
    }

    @MainActor
    private func ensurePrimaryPostersLoadedIfNeeded() async {
        if availablePosters.isEmpty {
            await fetchPrimaryPosters()
        } else {
            syncLoadStateWithCurrentData()
        }
    }

    @MainActor
    private func fetchPrimaryPosters() async {
        do {
            imageLoadState = .loading
            let posters = try await primaryPosterRequest()
            availablePosters = posters.filteredAndSorted()
            if !useSeriesPoster {
                syncLoadStateWithCurrentData(sourceOverride: availablePosters)
            }
        } catch {
            logger.error("Error fetching posters: \(error.localizedDescription)")
            imageLoadState = .error(error)
        }
    }

    @MainActor
    private func fetchSeriesPostersIfNeeded() async {
        guard case .season(_, let parentSeriesID) = type else { return }
        if !seriesPosters.isEmpty {
            if useSeriesPoster {
                syncLoadStateWithCurrentData()
            }
            return
        }

        do {
            imageLoadState = .loading
            seriesPosters = try await fetcher.postersForSeries(
                seriesID: parentSeriesID,
                idealWidth: Constants.idealWidth
            )
            .filteredAndSorted()
            if useSeriesPoster {
                syncLoadStateWithCurrentData(sourceOverride: seriesPosters)
            }
        } catch {
            logger.error("Error fetching posters: \(error.localizedDescription)")
            imageLoadState = .error(error)
        }
    }

    @MainActor
    private func primaryPosterRequest() async throws -> [Poster] {
        switch type {
        case .movie:
            return try await fetcher.postersForMovie(
                for: tmdbID,
                idealWidth: Constants.idealWidth)
        case .series:
            return try await fetcher.postersForSeries(
                seriesID: tmdbID,
                idealWidth: Constants.idealWidth)
        case .season(let seasonNumber, let parentSeriesID):
            return try await fetcher.postersForSeason(
                forSeason: seasonNumber,
                inParentSeries: parentSeriesID,
                idealWidth: Constants.idealWidth)
        }
    }

    @MainActor
    private func syncLoadStateWithCurrentData(sourceOverride: [Poster]? = nil) {
        let posters = sourceOverride ?? currentPosters
        imageLoadState = posters.isEmpty ? .empty : .loaded
    }

    private enum ImageLoadState {
        case loading
        case loaded
        case empty
        case error(Error)
    }
}

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

extension Array where Element == Poster {
    func filteredAndSorted(language: Language = .japanese) -> [Poster] {
        let prioritized = self.sorted {
            $0.metadata.width > $1.metadata.width
        }

        let filtered = prioritized.filter { $0.metadata.languageCode == language.rawValue }
        return filtered.isEmpty ? prioritized : filtered
    }
}

#Preview {
    NavigationStack {
        PosterSelectionView(
            tmdbID: 307972,
            type: .season(seasonNumber: 1, parentSeriesID: 209867),
            onPosterSelected: { _ in }
        )
    }
}

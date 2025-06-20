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
    let fetcher: InfoFetcher
    
    init(entry: AnimeEntry, infoFetcher: InfoFetcher = .init()) {
        self.entry = entry
        self.fetcher = infoFetcher
    }
    
    @State var availablePosters: [Poster] = []
    @State var seriesPosters: [Poster] = []
    @State var previewPoster: Poster?
    @State var useSeriesPoster: Bool = false
    @Environment(\.dismiss) var dismiss
    @Namespace var preview

    @MainActor
    private struct Constants {
        static let navigationTitle: LocalizedStringKey = "Pick a poster"
        static let gridItemMinSize: CGFloat = 100
        static let gridItemMaxSize: CGFloat = 200
        static let gridItemVerticalSpacing: CGFloat = 12
        static let gridItemHorizontalSpacing: CGFloat = 12
        static let idealWidth: Int = 200
        static let pickerPadding: CGFloat = 5
        static let posterCornerRadius: CGFloat = 5
        static let cacheExpiration: StorageExpiration = .seconds(180)
    }
    
    var body: some View {
        VStack {
            if entry.isSeason {
                Picker(selection: $useSeriesPoster) {
                    Text("Season").tag(false)
                    Text("TV Series").tag(true)
                } label: { }
                .pickerStyle(.segmented)
                .padding(.bottom, Constants.pickerPadding)
            }
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: Constants.gridItemMinSize, maximum: Constants.gridItemMaxSize),
                                             spacing: Constants.gridItemHorizontalSpacing)],
                          spacing: Constants.gridItemVerticalSpacing) {
                    ForEach(useSeriesPoster ? seriesPosters : availablePosters, id: \.url) { poster in
                        posterWithInfo(poster: poster)
                            .transition(.opacity)
                            .onTapGesture {
                                previewPoster = poster
                            }
                    }
                }
            }
            .animation(.default, value: useSeriesPoster)
            .animation(.default, value: availablePosters)
        }
        .padding(.horizontal)
        .navigationTitle(Constants.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $previewPoster) { poster in
            PosterPreview(previewPoster: poster, updatePoster: { url in
                entry.posterURL = url
                entry.usingCustomPoster = true
                logger.info("Updated poster for ID: \(entry.tmdbID)")
                dismiss()
            })
            .navigationTransition(.zoom(sourceID: poster.metadata.filePath,
                                        in: preview))
        }
        .onChange(of: useSeriesPoster) {
            Task {
                if let tmdbID = entry.parentSeriesID,
                   useSeriesPoster,
                   seriesPosters.isEmpty {
                    seriesPosters = try await fetcher.postersForSeries(seriesID: tmdbID,
                                                                       idealWidth: Constants.idealWidth)
                    .filteredAndSorted()
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
            PosterView(url: poster.url, diskCacheExpiration: Constants.cacheExpiration)
                .clipShape(RoundedRectangle(cornerRadius: Constants.posterCornerRadius))
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
                posters = try await fetcher.postersForMovie(for: entry.tmdbID, idealWidth: Constants.idealWidth)
            case .series:
                posters = try await fetcher.postersForSeries(seriesID: entry.tmdbID, idealWidth: Constants.idealWidth)
            case let .season(seasonNumber, parentSeriesID):
                posters = try await fetcher.postersForSeason(forSeason: seasonNumber,
                                                             inParentSeries: parentSeriesID,
                                                             idealWidth: Constants.idealWidth)
            }
            availablePosters = posters.filteredAndSorted()
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
            Text("\(previewPoster.metadata.width) x \(previewPoster.metadata.height)")
                .font(.caption)
                .foregroundStyle(.gray)
            PosterView(url: previewPosterURL, diskCacheExpiration: .seconds(3600))
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
    func filteredAndSorted(language: Language = .japanese) -> [Poster] {
        self
            .filter { $0.metadata.languageCode == language.rawValue }
            .sorted { $0.metadata.width > $1.metadata.width }
    }
}

#Preview {
    NavigationStack {
        PosterSelectionView(entry: .init(name: "Frieren",
                                         type: .season(seasonNumber: 1, parentSeriesID: 209867),
                                         tmdbID: 307972))
    }
}

//
//  AnimeSharingController.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/11/22.
//

import SwiftUI
import DataProvider
import Kingfisher
import UniformTypeIdentifiers
import CoreGraphics
import CoreImage
import Observation

@MainActor @Observable
final class AnimeSharingController {
    static let previewCardWidth: CGFloat = 360

    private static let defaultAspectRatio: CGFloat = 2.0 / 3.0
    private static let minAspectRatio: CGFloat = 0.45
    private static let maxAspectRatio: CGFloat = 0.85
    private static let jpegQuality: CGFloat = 0.9

    private static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy"
        return formatter
    }()

    private static let validLanguageCodes: Set<String> = ["ja-JP", "zh-CN", "en-US"]
    private static let languageCodeToLanguage: [String: Language] = [
        "ja-JP": .japanese,
        "zh-CN": .chinese,
        "en-US": .english
    ]

    let entry: AnimeEntry

    var selectedLanguage: Language
    var selectedPosterURL: URL?
    private(set) var renderedImageURL: URL?
    private(set) var loadedImage: UIImage?

    var availableLanguages: [Language] {
        Array(translations.keys).sorted { $0.rawValue < $1.rawValue }
    }

    var canSelectLanguage: Bool {
        !translations.isEmpty
    }

    var currentTitle: String {
        title(for: selectedLanguage)
    }

    var previewSubtitle: String? {
        subtitle(for: selectedLanguage)
    }

    var previewDetailLine: String? {
        detailLineText()
    }

    var previewAspectRatio: CGFloat {
        aspectRatio(for: loadedImage)
    }

    var renderTrigger: SharingCardRenderTrigger {
        SharingCardRenderTrigger(posterURL: selectedPosterURL, language: selectedLanguage)
    }

    private var translations: [Language: String]
    @ObservationIgnored private var renderCache: [SharingCardRenderTrigger: URL] = [:]
    @ObservationIgnored private var lastLoadedPosterURL: URL?
    @ObservationIgnored private var preferredLanguage: Language
    @ObservationIgnored private let pipeline: SharingCardExportPipeline

    init(entry: AnimeEntry, defaultLanguage: Language = .english) {
        self.entry = entry.parentSeriesEntry ?? entry
        self.selectedPosterURL = self.entry.posterURL
        self.selectedLanguage = defaultLanguage
        self.preferredLanguage = defaultLanguage
        self.translations = AnimeSharingController.buildTranslations(from: self.entry)
        self.pipeline = SharingCardExportPipeline(
            baseWidth: AnimeSharingController.previewCardWidth,
            jpegQuality: AnimeSharingController.jpegQuality)
        applyPreferredLanguage(defaultLanguage, respectingCurrentSelection: false)
    }

    func applyPreferredLanguage(_ language: Language, respectingCurrentSelection: Bool) {
        preferredLanguage = language
        guard !availableLanguages.isEmpty else { return }

        if respectingCurrentSelection, availableLanguages.contains(selectedLanguage) {
            return
        }

        if availableLanguages.contains(language) {
            selectedLanguage = language
        } else if let fallback = availableLanguages.first {
            selectedLanguage = fallback
        }
    }

    func updateSelectedPosterURL(_ url: URL?) {
        let resolvedURL = url ?? entry.posterURL
        guard selectedPosterURL != resolvedURL else { return }
        selectedPosterURL = resolvedURL
    }

    func processRenderRequest(for trigger: SharingCardRenderTrigger) async {
        guard let posterURL = trigger.posterURL else { return }
        guard !Task.isCancelled else { return }

        if let cachedURL = renderCache[trigger] {
            useCachedRender(at: cachedURL, for: trigger)
            return
        }

        let image: UIImage?

        if lastLoadedPosterURL == posterURL, let cachedImage = loadedImage {
            image = cachedImage
        } else {
            image = await loadImage(from: posterURL)
        }

        guard !Task.isCancelled else { return }
        guard let image else { return }
        await renderPoster(using: image, for: trigger)
    }

    func cleanupRenderedFiles() {
        for url in renderCache.values {
            try? FileManager.default.removeItem(at: url)
        }
        renderCache.removeAll()
        renderedImageURL = nil
    }

    private func loadImage(from url: URL) async -> UIImage? {
        do {
            let image = try await pipeline.loadImage(from: url)
            loadedImage = image
            lastLoadedPosterURL = url
            return image
        } catch is CancellationError {
            return nil
        } catch {
            print("Error loading image: \(error)")
            return nil
        }
    }

    private func renderPoster(using image: UIImage, for trigger: SharingCardRenderTrigger) async {
        guard !Task.isCancelled else { return }
        let language = trigger.language
        let metadata = PosterMetadata(
            title: title(for: language),
            subtitle: subtitle(for: language),
            detail: detailLineText()
        )
        let aspectRatio = aspectRatio(for: image)
        let fileName = fileName(for: trigger)

        do {
            let fileURL = try await pipeline.renderPoster(
                image: image,
                metadata: metadata,
                aspectRatio: aspectRatio,
                fileName: fileName
            )
            guard !Task.isCancelled else { return }
            storeRenderedFile(fileURL, for: trigger)
        } catch is CancellationError {
            return
        } catch {
            print("Error rendering poster: \(error)")
        }
    }

    private func fileName(for trigger: SharingCardRenderTrigger) -> String {
        "poster_\(entry.tmdbID)_\(trigger.language).jpg"
    }

    private func storeRenderedFile(_ url: URL, for trigger: SharingCardRenderTrigger) {
        if let existingURL = renderCache[trigger], existingURL != url {
            try? FileManager.default.removeItem(at: existingURL)
        }
        renderCache[trigger] = url
        useCachedRender(at: url, for: trigger)
    }

    private func useCachedRender(at url: URL, for trigger: SharingCardRenderTrigger) {
        renderedImageURL = url
    }

    private func title(for language: Language) -> String {
        translations[language] ?? entry.name
    }

    private func subtitle(for language: Language) -> String? {
        let localized = title(for: language).trimmingCharacters(in: .whitespacesAndNewlines)
        let base = entry.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard localized.caseInsensitiveCompare(base) != .orderedSame else { return nil }
        return base
    }

    private func detailLineText() -> String? {
        var parts: [String] = []
        if let year = releaseYearText() {
            parts.append(year)
        }
        parts.append(entryTypeLabel())
        return parts.joined(separator: " • ")
    }

    private func releaseYearText() -> String? {
        guard let date = entry.onAirDate else { return nil }
        return AnimeSharingController.yearFormatter.string(from: date)
    }

    private func entryTypeLabel() -> String {
        switch entry.type {
        case .movie:
            return "Movie"
        case .series:
            return "TV Series"
        case .season(let seasonNumber, _):
            return "Season \(seasonNumber)"
        }
    }

    private func aspectRatio(for image: UIImage?) -> CGFloat {
        guard let image else { return AnimeSharingController.defaultAspectRatio }
        let ratio = image.size.width / max(image.size.height, 1)
        return AnimeSharingController.clampAspectRatio(ratio)
    }

    private static func clampAspectRatio(_ ratio: CGFloat) -> CGFloat {
        guard ratio.isFinite, ratio > 0 else { return defaultAspectRatio }
        return min(max(ratio, minAspectRatio), maxAspectRatio)
    }

    private static func buildTranslations(from entry: AnimeEntry) -> [Language: String] {
        entry.nameTranslations.reduce(into: [Language: String]()) { result, pair in
            guard let language = languageCodeToLanguage[pair.key], validLanguageCodes.contains(pair.key) else {
                return
            }
            result[language] = pair.value.isEmpty ? entry.name : pair.value
        }
    }
}

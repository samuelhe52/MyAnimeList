//
//  PosterExportController.swift
//  MyAnimeList
//
//  Created by GitHub Copilot on 2025/11/22.
//

import SwiftUI
import DataProvider
import Kingfisher
import UniformTypeIdentifiers
import CoreGraphics
import CoreImage
import Observation

@MainActor @Observable
final class PosterExportController {
    static let previewCardWidth: CGFloat = 320

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

    var renderTrigger: PosterExportRenderTrigger {
        PosterExportRenderTrigger(posterURL: selectedPosterURL, language: selectedLanguage)
    }

    private var translations: [Language: String]
    @ObservationIgnored private var renderCache: [PosterExportRenderTrigger: URL] = [:]
    @ObservationIgnored private var lastLoadedPosterURL: URL?
    @ObservationIgnored private var preferredLanguage: Language
    @ObservationIgnored private let pipeline: PosterExportPipeline

    init(entry: AnimeEntry, defaultLanguage: Language = .english) {
        self.entry = entry.parentSeriesEntry ?? entry
        self.selectedPosterURL = self.entry.posterURL
        self.selectedLanguage = defaultLanguage
        self.preferredLanguage = defaultLanguage
        self.translations = PosterExportController.buildTranslations(from: self.entry)
        self.pipeline = PosterExportPipeline(
            baseWidth: PosterExportController.previewCardWidth,
            jpegQuality: PosterExportController.jpegQuality)
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

    func processRenderRequest(for trigger: PosterExportRenderTrigger) async {
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

    private func renderPoster(using image: UIImage, for trigger: PosterExportRenderTrigger) async {
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

    private func fileName(for trigger: PosterExportRenderTrigger) -> String {
        "poster_\(entry.tmdbID)_\(trigger.language).jpg"
    }

    private func storeRenderedFile(_ url: URL, for trigger: PosterExportRenderTrigger) {
        if let existingURL = renderCache[trigger], existingURL != url {
            try? FileManager.default.removeItem(at: existingURL)
        }
        renderCache[trigger] = url
        useCachedRender(at: url, for: trigger)
    }

    private func useCachedRender(at url: URL, for trigger: PosterExportRenderTrigger) {
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
        return PosterExportController.yearFormatter.string(from: date)
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
        guard let image else { return PosterExportController.defaultAspectRatio }
        let ratio = image.size.width / max(image.size.height, 1)
        return PosterExportController.clampAspectRatio(ratio)
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

struct PosterExportRenderTrigger: Hashable {
    let posterURL: URL?
    let language: Language
}

private struct PosterMetadata {
    let title: String
    let subtitle: String?
    let detail: String?
}

private enum PosterExportError: LocalizedError {
    case renderFailed
    case persistFailed
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .renderFailed:
            return "Unable to render poster preview."
        case .persistFailed:
            return "Unable to persist rendered poster to disk."
        case .invalidImage:
            return "Poster data is invalid."
        }
    }
}

@MainActor
private struct PosterExportPipeline {
    private let baseWidth: CGFloat
    private let jpegQuality: CGFloat

    init(baseWidth: CGFloat, jpegQuality: CGFloat) {
        self.baseWidth = baseWidth
        self.jpegQuality = jpegQuality
    }

    func loadImage(from url: URL) async throws -> UIImage {
        let result = try await KingfisherManager.shared.retrieveImage(with: url)
        try Task.checkCancellation()
        return PosterExportPipeline.convertToSRGB(result.image)
    }

    func renderPoster(
        image: UIImage,
        metadata: PosterMetadata,
        aspectRatio: CGFloat,
        fileName: String
    ) async throws -> URL {
        let baseHeight = baseWidth / max(aspectRatio, 0.0001)
        let nativePixelWidth = image.cgImage.map { CGFloat($0.width) } ?? image.size.width * image.scale
        let exportWidth = max(nativePixelWidth, baseWidth)
        let scaleFactor = max(exportWidth / baseWidth, 1)

        let renderer = ImageRenderer(content:
            PosterCardView(
                image: image,
                title: metadata.title,
                subtitle: metadata.subtitle,
                detail: metadata.detail,
                aspectRatio: aspectRatio
            )
            .frame(width: baseWidth, height: baseHeight)
        )
        renderer.scale = scaleFactor

        guard let renderedImage = renderer.uiImage else {
            throw PosterExportError.renderFailed
        }

        let normalizedImage = PosterExportPipeline.convertToSRGB(renderedImage)
        return try await persist(normalizedImage, fileName: fileName)
    }

    private func persist(_ image: UIImage, fileName: String) async throws -> URL {
        try await Task.detached(priority: .utility) {
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(fileName)

            guard let cgImage = image.cgImage else {
                throw PosterExportError.invalidImage
            }

            guard
                let destination = CGImageDestinationCreateWithURL(
                    fileURL as CFURL,
                    UTType.jpeg.identifier as CFString,
                    1,
                    nil
                )
            else {
                throw PosterExportError.persistFailed
            }

            let options: [CFString: Any] = [
                kCGImageDestinationLossyCompressionQuality: jpegQuality
            ]

            CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)

            guard CGImageDestinationFinalize(destination) else {
                try? FileManager.default.removeItem(at: fileURL)
                throw PosterExportError.persistFailed
            }

            return fileURL
        }.value
    }

    private static let srgbColorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    private static let ciContext: CIContext = CIContext(options: [
        .workingColorSpace: PosterExportPipeline.srgbColorSpace,
        .outputColorSpace: PosterExportPipeline.srgbColorSpace
    ])

    private static func convertToSRGB(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        let extent = ciImage.extent.integral
        guard let cgImage = PosterExportPipeline.ciContext.createCGImage(
            ciImage,
            from: extent,
            format: .RGBA8,
            colorSpace: PosterExportPipeline.srgbColorSpace
        ) else { return image }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

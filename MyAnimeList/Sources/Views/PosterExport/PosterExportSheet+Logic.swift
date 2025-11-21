import SwiftUI
import DataProvider
import Kingfisher
import UniformTypeIdentifiers
import CoreGraphics
import CoreImage

@MainActor
final class PosterExportViewModel: ObservableObject {
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

    @Published var selectedLanguage: Language
    @Published var selectedPosterURL: URL?
    @Published private(set) var renderedImageURL: URL?
    @Published private(set) var loadedImage: UIImage?

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
    private var renderCache: [PosterExportRenderTrigger: URL] = [:]
    private var lastLoadedPosterURL: URL?
    private var preferredLanguage: Language

    init(entry: AnimeEntry, defaultLanguage: Language = .english) {
        self.entry = entry.parentSeriesEntry ?? entry
        self.selectedPosterURL = self.entry.posterURL
        self.selectedLanguage = defaultLanguage
        self.preferredLanguage = defaultLanguage
        self.translations = PosterExportViewModel.buildTranslations(from: self.entry)
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
        guard selectedPosterURL != url else { return }
        selectedPosterURL = url
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
            let result = try await KingfisherManager.shared.retrieveImage(with: url)
            try Task.checkCancellation()
            let image = convertToSRGB(result.image)
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
        let aspectRatio = aspectRatio(for: image)
        let baseWidth = PosterExportViewModel.previewCardWidth
        let baseHeight = baseWidth / max(aspectRatio, 0.0001)
        let nativePixelWidth = image.cgImage.map { CGFloat($0.width) } ?? image.size.width * image.scale
        let exportWidth = max(nativePixelWidth, baseWidth)
        let scaleFactor = max(exportWidth / baseWidth, 1)

        let metadata = PosterMetadata(
            title: title(for: language),
            subtitle: subtitle(for: language),
            detail: detailLineText()
        )

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

        guard let renderedImage = renderer.uiImage else { return }
        guard !Task.isCancelled else { return }

        let normalizedImage = convertToSRGB(renderedImage)
        let fileName = "poster_\(entry.tmdbID)_\(language).jpg"

        guard let fileURL = await persist(normalizedImage, fileName: fileName) else { return }
        guard !Task.isCancelled else { return }

        storeRenderedFile(fileURL, for: trigger)
    }

    private func persist(_ image: UIImage, fileName: String) async -> URL? {
        let quality = PosterExportViewModel.jpegQuality
        return await Task.detached(priority: .utility) {
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(fileName)

            guard let cgImage = image.cgImage else { return nil }

            guard
                let destination = CGImageDestinationCreateWithURL(
                    fileURL as CFURL,
                    UTType.jpeg.identifier as CFString,
                    1,
                    nil
                )
            else {
                return nil
            }

            let options: [CFString: Any] = [
                kCGImageDestinationLossyCompressionQuality: quality
            ]

            CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)

            guard CGImageDestinationFinalize(destination) else {
                try? FileManager.default.removeItem(at: fileURL)
                return nil
            }

            return fileURL
        }.value
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
        return PosterExportViewModel.yearFormatter.string(from: date)
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
        guard let image else { return PosterExportViewModel.defaultAspectRatio }
        let ratio = image.size.width / max(image.size.height, 1)
        return PosterExportViewModel.clampAspectRatio(ratio)
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

private let posterExportSRGBColorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
private let posterExportCIContext: CIContext = CIContext(options: [
    .workingColorSpace: posterExportSRGBColorSpace,
    .outputColorSpace: posterExportSRGBColorSpace
])

private func convertToSRGB(_ image: UIImage) -> UIImage {
    guard let ciImage = CIImage(image: image) else { return image }
    let extent = ciImage.extent.integral
    guard let cgImage = posterExportCIContext.createCGImage(
        ciImage,
        from: extent,
        format: .RGBA8,
        colorSpace: posterExportSRGBColorSpace
    ) else { return image }
    return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
}

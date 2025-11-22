import Foundation
import SwiftUI
import UIKit
import os

@MainActor
struct SharingCardRenderOutcome {
    let imageURL: URL
    let image: UIImage?
    let aspectRatio: CGFloat
}

@MainActor
final class SharingCardRenderer {
    private let pipeline: SharingCardExportPipeline
    private let defaultAspectRatio: CGFloat
    private let minAspectRatio: CGFloat
    private let maxAspectRatio: CGFloat

    private var renderCache: [SharingCardRenderTrigger: URL] = [:]
    private var lastLoadedPosterURL: URL?
    private var cachedImage: UIImage?
    private var cachedAspectRatio: CGFloat

    private let logger = Logger(subsystem: "com.samuelhe.MyAnimeList", category: "SharingCardRenderer")

    init(
        baseWidth: CGFloat,
        jpegQuality: CGFloat,
        defaultAspectRatio: CGFloat,
        minAspectRatio: CGFloat,
        maxAspectRatio: CGFloat
    ) {
        self.pipeline = SharingCardExportPipeline(baseWidth: baseWidth, jpegQuality: jpegQuality)
        self.defaultAspectRatio = defaultAspectRatio
        self.minAspectRatio = minAspectRatio
        self.maxAspectRatio = maxAspectRatio
        self.cachedAspectRatio = defaultAspectRatio
    }

    func renderPoster(
        for trigger: SharingCardRenderTrigger,
        metadata: PosterMetadata,
        fileName: String
    ) async -> SharingCardRenderOutcome? {
        guard let posterURL = trigger.posterURL else { return nil }
        guard !Task.isCancelled else { return nil }

        if let cachedURL = renderCache[trigger] {
            return SharingCardRenderOutcome(
                imageURL: cachedURL,
                image: cachedImage,
                aspectRatio: cachedAspectRatio
            )
        }

        guard let image = await loadImageIfNeeded(from: posterURL) else { return nil }
        guard !Task.isCancelled else { return nil }

        do {
            let aspectRatio = clampAspectRatio(for: image)
            let fileURL = try await pipeline.renderPoster(
                image: image,
                metadata: metadata,
                aspectRatio: aspectRatio,
                fileName: fileName
            )
            renderCache[trigger] = fileURL
            cachedAspectRatio = aspectRatio
            return SharingCardRenderOutcome(imageURL: fileURL, image: image, aspectRatio: aspectRatio)
        } catch is CancellationError {
            return nil
        } catch {
            logger.error("Error rendering poster: \(error.localizedDescription)")
            return nil
        }
    }

    func cleanup() {
        for url in renderCache.values {
            try? FileManager.default.removeItem(at: url)
        }
        renderCache.removeAll()
        cachedImage = nil
        lastLoadedPosterURL = nil
        cachedAspectRatio = defaultAspectRatio
    }

    private func loadImageIfNeeded(from url: URL) async -> UIImage? {
        if lastLoadedPosterURL == url, let cachedImage {
            return cachedImage
        }

        do {
            let image = try await pipeline.loadImage(from: url)
            cachedImage = image
            lastLoadedPosterURL = url
            cachedAspectRatio = clampAspectRatio(for: image)
            return image
        } catch is CancellationError {
            return nil
        } catch {
            logger.error("Error loading image: \(error.localizedDescription)")
            return nil
        }
    }

    private func clampAspectRatio(for image: UIImage) -> CGFloat {
        let ratio = image.size.width / max(image.size.height, 1)
        return clampAspectRatio(ratio)
    }

    private func clampAspectRatio(_ ratio: CGFloat) -> CGFloat {
        guard ratio.isFinite, ratio > 0 else { return defaultAspectRatio }
        return min(max(ratio, minAspectRatio), maxAspectRatio)
    }
}

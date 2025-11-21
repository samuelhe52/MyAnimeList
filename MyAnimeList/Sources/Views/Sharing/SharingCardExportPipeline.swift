//
//  SharingCardExportPipeline.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/11/22.
//

import Foundation
import Kingfisher
import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct SharingCardExportPipeline {
    private let baseWidth: CGFloat
    private let jpegQuality: CGFloat

    init(baseWidth: CGFloat, jpegQuality: CGFloat) {
        self.baseWidth = baseWidth
        self.jpegQuality = jpegQuality
    }

    func loadImage(from url: URL) async throws -> UIImage {
        let result = try await KingfisherManager.shared.retrieveImage(with: url)
        try Task.checkCancellation()
        return SharingCardExportPipeline.convertToSRGB(result.image)
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
            SharingCardView(
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
            throw SharingCardRenderError.renderFailed
        }

        let normalizedImage = SharingCardExportPipeline.convertToSRGB(renderedImage)
        return try await persist(normalizedImage, fileName: fileName)
    }

    private func persist(_ image: UIImage, fileName: String) async throws -> URL {
        try await Task.detached(priority: .utility) {
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(fileName)

            guard let cgImage = image.cgImage else {
                throw SharingCardRenderError.invalidImage
            }

            guard
                let destination = CGImageDestinationCreateWithURL(
                    fileURL as CFURL,
                    UTType.jpeg.identifier as CFString,
                    1,
                    nil
                )
            else {
                throw SharingCardRenderError.persistFailed
            }

            let options: [CFString: Any] = [
                kCGImageDestinationLossyCompressionQuality: jpegQuality
            ]

            CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)

            guard CGImageDestinationFinalize(destination) else {
                try? FileManager.default.removeItem(at: fileURL)
                throw SharingCardRenderError.persistFailed
            }

            return fileURL
        }.value
    }

    private static let srgbColorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    private static let ciContext: CIContext = CIContext(options: [
        .workingColorSpace: SharingCardExportPipeline.srgbColorSpace,
        .outputColorSpace: SharingCardExportPipeline.srgbColorSpace
    ])

    private static func convertToSRGB(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        let extent = ciImage.extent.integral
        guard let cgImage = SharingCardExportPipeline.ciContext.createCGImage(
            ciImage,
            from: extent,
            format: .RGBA8,
            colorSpace: SharingCardExportPipeline.srgbColorSpace
        ) else { return image }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

struct SharingCardRenderTrigger: Hashable {
    let posterURL: URL?
    let language: Language
}

struct PosterMetadata {
    let title: String
    let subtitle: String?
    let detail: String?
}

enum SharingCardRenderError: LocalizedError {
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

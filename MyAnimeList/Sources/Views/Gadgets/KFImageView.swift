//
//  KFImageView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/11.
//

import Kingfisher
import SwiftUI
import os

fileprivate let logger = Logger(subsystem: .bundleIdentifier, category: "PosterView")

struct KFImageView: View {
    let url: URL?
    let diskCacheExpiration: StorageExpiration
    let targetWidth: CGFloat?
    @Binding var imageLoaded: Bool
    @State private var image: UIImage? = nil

    init(
        url: URL?,
        targetWidth: CGFloat? = nil,
        diskCacheExpiration: StorageExpiration,
        imageLoaded: Binding<Bool> = .constant(false)
    ) {
        self.url = url
        self.diskCacheExpiration = diskCacheExpiration
        self.targetWidth = targetWidth
        self._imageLoaded = imageLoaded
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
            } else {
                ProgressView()
                    .frame(minWidth: 100, minHeight: 100)
            }
        }
        .onChange(of: url, initial: true) {
            Task { await loadImage() }
        }
    }

    private func loadImage() async {
        var kfRetrieveOptions: KingfisherOptionsInfo = [
            .cacheOriginalImage,
            .diskCacheExpiration(diskCacheExpiration),
            .onFailureImage(UIImage(named: "missing_image_resource"))
        ]

        if let targetWidth {
            let size = CGSize(width: targetWidth, height: targetWidth * 1.5)
            let processor = DownsamplingImageProcessor(size: size)
            kfRetrieveOptions.append(.processor(processor))
        }

        if let url {
            do {
                let result = try await KingfisherManager.shared
                    .retrieveImage(with: url, options: kfRetrieveOptions)
                withAnimation {
                    image = result.image
                    imageLoaded = true
                }
            } catch {
                logger.warning("Error loading image: \(error)")
                imageLoaded = false
            }
        } else {
            image = UIImage(named: "missing_image_resource")
            imageLoaded = false
        }
    }
}

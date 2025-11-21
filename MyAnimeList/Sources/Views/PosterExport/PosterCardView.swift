//
//  PosterCardView.swift
//  MyAnimeList
//
//  Created by GitHub Copilot on 2025/11/22.
//

import SwiftUI

struct PosterCardView: View {
    let image: UIImage?
    let title: String
    let subtitle: String?
    let detail: String?
    let aspectRatio: CGFloat

    private let minAspectRatio: CGFloat = 0.45
    private let maxAspectRatio: CGFloat = 0.85

    private var safeAspectRatio: CGFloat {
        max(minAspectRatio, min(aspectRatio, maxAspectRatio))
    }

    var body: some View {
        ZStack {
            backdropLayer

            overlayGradient

            VStack(alignment: .leading, spacing: 10) {
                if let detail {
                    Text(detail.uppercased())
                        .font(.caption.smallCaps())
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.12), in: Capsule())
                }

                Text(title)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)

                if let subtitle {
                    Text(subtitle)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(24)
        }
        .aspectRatio(safeAspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 25)
    }

    private var backdropLayer: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .overlay(Color.black.opacity(0.15))
        .overlay(
            Rectangle()
                .fill(.black.opacity(0.4))
                .blendMode(.overlay)
        )
    }

    private var overlayGradient: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.0),
                Color.black.opacity(0.1),
                Color.black.opacity(0.65),
                Color.black.opacity(0.85)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    PosterCardView(
        image: UIImage(systemName: "photo"),
        title: "Frieren: Beyond Journey's End",
        subtitle: "葬送のフリーレン",
        detail: "2023 • TV Series",
        aspectRatio: 2 / 3
    )
    .padding()
    .background(Color.black)
}

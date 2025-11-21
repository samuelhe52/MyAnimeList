//
//  PosterExportPreviewSection.swift
//  MyAnimeList
//
//  Created by GitHub Copilot on 2025/11/22.
//

import SwiftUI
import DataProvider

struct PosterExportPreviewSection: View {
    let title: String
    let subtitle: String?
    let detail: String?
    let aspectRatio: CGFloat
    let image: UIImage?
    let animationTrigger: Language

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Preview")
                .font(.headline)
                .foregroundStyle(.secondary)

            PosterCardView(
                image: image,
                title: title,
                subtitle: subtitle,
                detail: detail,
                aspectRatio: aspectRatio
            )
            .animation(
                .spring(response: 0.35, dampingFraction: 0.85),
                value: animationTrigger
            )
            .frame(maxWidth: PosterExportController.previewCardWidth)
            .padding(12)
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: 12)
    }
}

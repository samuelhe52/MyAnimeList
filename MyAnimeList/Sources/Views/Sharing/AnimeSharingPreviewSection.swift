//
//  AnimeSharingPreviewSection.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/11/22.
//

import SwiftUI
import DataProvider

struct AnimeSharingPreviewSection: View {
    @Environment(\.colorScheme) var colorScheme
    
    let title: AttributedString
    let subtitle: AttributedString?
    let detail: String?
    let aspectRatio: CGFloat
    let image: UIImage?
    let animationTrigger: Language

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Preview")
                .font(.headline)
                .foregroundStyle(.secondary)

            SharingCardView(
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
            .frame(maxWidth: AnimeSharingController.previewCardWidth)
            .padding(12)
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.4), lineWidth: 1)
            )
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: 12)
    }
}

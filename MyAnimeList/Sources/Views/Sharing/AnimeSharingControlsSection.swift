//
//  AnimeSharingControlsSection.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/11/22.
//

import DataProvider
import SwiftUI

struct AnimeSharingControlsSection: View {
    let availableLanguages: [Language]
    @Binding var selectedLanguage: Language
    let canSelectLanguage: Bool
    let onChangePoster: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Controls")
                .font(.headline)
                .foregroundStyle(.secondary)

            if canSelectLanguage {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Language")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(availableLanguages, id: \.self) { language in
                            Text(language.localizedStringResource).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Artwork")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button(action: onChangePoster) {
                    Label("Change Poster", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 10)
    }
}

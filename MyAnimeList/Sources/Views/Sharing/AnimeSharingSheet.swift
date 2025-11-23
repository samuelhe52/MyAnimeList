//
//  AnimeSharingSheet.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/11/22.
//

import DataProvider
import SwiftUI

struct AnimeSharingSheet: View {
    @State private var controller: AnimeSharingController
    @Environment(\.dismiss) private var dismiss
    @AppStorage(.preferredAnimeInfoLanguage) private var defaultLanguage: Language = .english

    @State private var showPosterSelection = false

    init(entry: AnimeEntry) {
        _controller = State(initialValue: AnimeSharingController(entry: entry))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    AnimeSharingPreviewSection(
                        title: controller.currentTitle,
                        subtitle: controller.previewSubtitle,
                        detail: controller.previewDetailLine,
                        aspectRatio: controller.previewAspectRatio,
                        image: controller.loadedImage,
                        animationTrigger: controller.selectedLanguage
                    )

                    AnimeSharingControlsSection(
                        availableLanguages: controller.availableLanguages,
                        selectedLanguage: $controller.selectedLanguage,
                        canSelectLanguage: controller.canSelectLanguage,
                        onChangePoster: { showPosterSelection = true }
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if let url = controller.renderedImageURL {
                        ShareLink(item: url) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Label("Rendering…", systemImage: "hourglass")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .fullScreenCover(isPresented: $showPosterSelection) {
                NavigationStack {
                    PosterSelectionView(
                        tmdbID: controller.entry.tmdbID,
                        type: controller.entry.type,
                        onPosterSelected: { url in
                            controller.updateSelectedPosterURL(url)
                        })
                }
            }
            .task(id: controller.renderTrigger) {
                let trigger = controller.renderTrigger
                await controller.processRenderRequest(for: trigger)
            }
            .onAppear {
                controller.applyPreferredLanguage(defaultLanguage, respectingCurrentSelection: false)
            }
            .onDisappear {
                controller.cleanupRenderedFiles()
            }
            .onChange(of: defaultLanguage, initial: false) { _, newValue in
                controller.applyPreferredLanguage(newValue, respectingCurrentSelection: true)
            }
        }
    }
}

#Preview {
    AnimeSharingSheet(entry: AnimeEntry.frieren)
}

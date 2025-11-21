import SwiftUI
import DataProvider

struct PosterExportSheet: View {
    @StateObject private var viewModel: PosterExportViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage(.preferredAnimeInfoLanguage) private var defaultLanguage: Language = .english

    @State private var showPosterSelection = false

    init(entry: AnimeEntry) {
        _viewModel = StateObject(wrappedValue: PosterExportViewModel(entry: entry))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    PosterExportPreviewSection(
                        title: viewModel.currentTitle,
                        subtitle: viewModel.previewSubtitle,
                        detail: viewModel.previewDetailLine,
                        aspectRatio: viewModel.previewAspectRatio,
                        image: viewModel.loadedImage,
                        animationTrigger: viewModel.selectedLanguage
                    )

                    PosterExportControlsSection(
                        availableLanguages: viewModel.availableLanguages,
                        selectedLanguage: $viewModel.selectedLanguage,
                        canSelectLanguage: viewModel.canSelectLanguage,
                        onChangePoster: { showPosterSelection = true }
                    )
                }
                .padding(.horizontal)
                .padding(.vertical, 24)
            }
            .navigationTitle("Export Poster")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if let url = viewModel.renderedImageURL {
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
                        tmdbID: viewModel.entry.tmdbID,
                        type: viewModel.entry.type,
                        onPosterSelected: { url in
                            viewModel.updateSelectedPosterURL(url)
                        })
                }
            }
            .task(id: viewModel.renderTrigger) {
                let trigger = viewModel.renderTrigger
                await viewModel.processRenderRequest(for: trigger)
            }
            .onAppear {
                viewModel.applyPreferredLanguage(defaultLanguage, respectingCurrentSelection: false)
            }
            .onDisappear {
                viewModel.cleanupRenderedFiles()
            }
            .onChange(of: defaultLanguage, initial: false) { _, newValue in
                viewModel.applyPreferredLanguage(newValue, respectingCurrentSelection: true)
            }
        }
    }
}

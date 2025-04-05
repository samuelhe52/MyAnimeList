//
//  AnimeEntryCard.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/23.
//

import SwiftUI
import Kingfisher

struct AnimeEntryCard: View {
    var entry: AnimeEntry
    @State private var posterImage: UIImage? = nil
    @State private var imageLoadError: Error? = nil
    
    var body: some View {
        image
            .padding()
            .alert("Image Load Error", isPresented: .constant(imageLoadError != nil), presenting: imageLoadError) { _ in
                Button("OK", role: .cancel) {
                    imageLoadError = nil
                }
            } message: { error in
                Text(error.localizedDescription)
            }
            .task { await loadImage() }
            .onChange(of: entry.posterURL) {
                Task.detached { await loadImage() }
            }
    }
    
    @ViewBuilder
    private var image: some View {
        if let posterImage {
                Image(uiImage: posterImage)
                    .resizable()
                    .clipShape(.rect(cornerRadius: 10))
                    .scaledToFit()
        } else {
            ProgressView()
                .frame(idealWidth: 150, idealHeight: 150)
        }
    }
    
    private func loadImage() async {
        guard let url = entry.posterURL else { return }
        do {
            let result = try await KingfisherManager.shared.retrieveImage(with: url)
            withAnimation {
                posterImage = result.image
            }
        } catch {
            imageLoadError = error
        }
    }
}

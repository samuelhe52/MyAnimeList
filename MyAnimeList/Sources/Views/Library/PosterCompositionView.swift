//
//  PosterCompositionView.swift
//  MyAnimeList
//
//  Created by AI Assistant on 2025/11/21.
//

import SwiftUI
import Kingfisher

struct PosterCompositionView: View {
    let image: UIImage?
    let title: String
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background Poster
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fit)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(2/3, contentMode: .fit)
            }
            
            // Blurred Banner
            HStack {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .padding(.top, 40)
            .background {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black, location: 0.3),
                                .init(color: .black, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            }
        }
        .background(Color.black) // Fallback background
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    PosterCompositionView(
        image: UIImage(systemName: "photo"),
        title: "Frieren: Beyond Journey's End"
    )
}

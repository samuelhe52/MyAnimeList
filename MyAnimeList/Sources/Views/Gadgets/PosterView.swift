//
//  PosterView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/11.
//

import SwiftUI
import Kingfisher

struct PosterView: View {
    let url: URL?
    
    var body: some View {
        Group {
            if let url {
                KFImage(url)
                    .resizable()
                    .fade(duration: 0.3)
                    .placeholder { ProgressView() }
                    .cacheOriginalImage()
                    .diskCacheExpiration(.days(1))
                    .cancelOnDisappear(true)
            } else {
                Image("missing_image_resource")
                    .resizable()
            }
        }
        .scaledToFit()
        .clipShape(.rect(cornerRadius: 6))
    }
}

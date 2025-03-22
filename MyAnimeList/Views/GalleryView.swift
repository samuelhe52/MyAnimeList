//
//  GalleryView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2024/12/8.
//

import SwiftUI

struct GalleryView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, My Anime List!")
        }
        .padding()
    }
}

#Preview {
    GalleryView()
}

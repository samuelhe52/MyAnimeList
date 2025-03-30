//
//  LibraryView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2024/12/8.
//

import SwiftUI

struct LibraryView: View {
    var store: LibraryStore
    
    var body: some View {
        Text("Hello, my library!")
    }
}

#Preview {
    @Previewable let store = LibraryStore()
    LibraryView(store: store)
}

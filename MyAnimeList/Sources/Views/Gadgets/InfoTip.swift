//
//  InfoTip.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/18.
//

import SwiftUI

struct InfoTip: View {
    @State var showTip: Bool = false
    var title: LocalizedStringKey
    var message: LocalizedStringKey
    var width: CGFloat?
    var height: CGFloat?

    var body: some View {
        Button(action: {
            showTip.toggle()
        }) {
            Image(systemName: "info.circle")
        }
        .popover(isPresented: $showTip) {
            VStack {
                Text(title)
                    .bold()
                    .foregroundStyle(.blue)
                Text(message)
                    .font(.caption)
            }
            .frame(width: width, height: height)
            .padding()
            .presentationCompactAdaptation(.popover)
        }
    }
}

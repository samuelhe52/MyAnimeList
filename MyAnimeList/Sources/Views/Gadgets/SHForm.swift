//
//  SHForm.swift
//  Goods Collector
//
//  Created by Samuel He on 2025/6/15.
//

import SwiftUI

struct SHForm<Content: View>: View {
    var content: Content
    let alignment: HorizontalAlignment
    
    init(@ViewBuilder content: () -> Content, alignment: HorizontalAlignment = .leading) {
        self.content = content()
        self.alignment = alignment
    }
    
    var body: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea(.all)
            .overlay{
                ScrollView {
                    LazyVStack(alignment: alignment, spacing: 20) {
                        content
                            .buttonStyle(.bordered)
                    }
                }
                .padding(20)
            }
    }
}

struct SHSection<Content: View>: View {
    var content: () -> Content
    let alignment: HorizontalAlignment
    let title: LocalizedStringKey?
    let spacing: CGFloat
    
    init(_ title: LocalizedStringKey?,
         alignment: HorizontalAlignment = .leading,
         spacing: CGFloat = 10,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.alignment = alignment
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            if let title {
                Text(title)
                    .font(.footnote)
                    .textCase(.uppercase)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 5)
                    .padding(.leading, 20)
            }
            LazyVStack(alignment: alignment, spacing: spacing) {
                content()
            }
            .padding(.top, 10)
            .padding(.horizontal)
            .padding(.bottom, 10)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.background)
            }
        }
        .buttonStyle(.borderless)
    }
}

struct SHRow<Content: View>: View {
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        content()
            .padding(.top, 10)
            .padding(.horizontal)
            .padding(.bottom, 10)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.background)
            }
    }
}

//
//  HighlightEffect.swift
//  MyAnimeList
//
//  Created by Samuel He on 7/10/25.
//

import SwiftUI

struct HighlightEffectModifier: ViewModifier {
    @Binding var showHighlight: Bool
    var highlightColor: Color
    var delay: TimeInterval
    var highlightDuration: TimeInterval
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(highlightColor, lineWidth: 3)
                    .fill(highlightColor.secondary.opacity(0.5))
                    .opacity(showHighlight ? 0.8 : 0)
            )
            .scaleEffect(showHighlight ? 1.05 : 1)
            .onChange(of: showHighlight, initial: true) {
                if showHighlight {
                    DispatchQueue.main.asyncAfter(deadline: .now() + highlightDuration) {
                        showHighlight = false
                    }
                }
            }
            .animation(.interactiveSpring(duration: highlightDuration - 0.05).delay(delay), value: showHighlight)
    }
}

extension View {
    func highlightEffect(showHighlight: Binding<Bool>,
                         color: Color = .yellow,
                         delay: TimeInterval = 0,
                         duration: TimeInterval = 0.5) -> some View {
        self.modifier(HighlightEffectModifier(showHighlight: showHighlight,
                                              highlightColor: color,
                                              delay: delay,
                                              highlightDuration: duration))
    }
}

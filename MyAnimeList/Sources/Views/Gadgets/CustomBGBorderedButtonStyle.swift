//
//  CustomBGBorderedButtonStyle.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/7/1.
//

import SwiftUI

struct CustomBGBorderedButtonStyle<S: ShapeStyle, V: Shape>: ButtonStyle {
    var shapeStyle: S
    var backgroundShape: V

    init(_ shapeStyle: S = .regularMaterial, backgroundIn backgroundShape: V = Capsule()) {
        self.shapeStyle = shapeStyle
        self.backgroundShape = backgroundShape
    }

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .foregroundStyle(.blue)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(shapeStyle, in: backgroundShape)
            .opacity(configuration.isPressed ? 0.95 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

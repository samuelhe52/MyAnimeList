//
//  ProportionalRoundedRectangle.swift
//  MyAnimeList
//
//  Created by Samuel He on 7/27/25.
//

import SwiftUI

struct ProportionalRoundedRectangle: Shape {
    let cornerFraction: CGFloat

    func path(in rect: CGRect) -> Path {
        let minSize = min(rect.width, rect.height)
        let cornerSize = min(0.5, max(0, cornerFraction)) * minSize
        return Path(
            roundedRect: rect,
            cornerSize: .init(width: cornerSize, height: cornerSize)
        )
    }
}

extension Shape where Self == ProportionalRoundedRectangle {
    static func proportionalRounded(cornerFraction: CGFloat = 0.1) -> Self {
        return ProportionalRoundedRectangle(cornerFraction: cornerFraction)
    }
    
    /// Default corner fraction is 0.1
    static var proportionalRounded: Self {
        return ProportionalRoundedRectangle(cornerFraction: 0.1)
    }
}

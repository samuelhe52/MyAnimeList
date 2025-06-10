//
//  SwiftUI+Helpers.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/11.
//

import SwiftUI

extension AnyTransition {
    static var opacityScale: AnyTransition { .opacity.combined(with: .scale) }
}

extension SensoryFeedback {
    static var lighterImpact: SensoryFeedback { .impact(weight: .light, intensity: 0.7) }
}

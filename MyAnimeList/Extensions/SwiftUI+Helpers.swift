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

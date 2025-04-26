//
//  GlobalToastsModifier.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/4/26.
//

import SwiftUI
import AlertToast

struct GlobalToastsModifier: ViewModifier {
    var center: ToastCenter
    
    func body(content: Content) -> some View {
        @Bindable var center = center
        content
            .toast(isPresenting: $center.copied,
                            duration: 1.5, offsetY: 20, alert: {
                         AlertToast(displayMode: .hud,
                                    type: .systemImage("checkmark.circle", .green),
                                    title: "Copied!")
                     })
                     .toast(isPresenting: $center.refreshingInfos,
                            offsetY: 20, alert: {
                         AlertToast(displayMode: .hud,
                                    type: .systemImage("arrow.clockwise.circle", .blue),
                                    title: "Refreshing infos...")
                     })
                     .toast(isPresenting: $center.prefetchingImages,
                            offsetY: 20, alert: {
                         AlertToast(displayMode: .hud,
                                    type: .systemImage("photo.on.rectangle.angled", .blue),
                                    title: "Prefetching images...")
                     })
                     .toast(isPresenting: $center.regularCompleted, offsetY: 20,
                            alert: {
                         AlertToast(displayMode: .hud,
                                    type: .complete(.green),
                                    title: "Completed.")
                     })
    }
}

extension View {
    func globalToasts(center: ToastCenter = .global) -> some View {
        self.modifier(GlobalToastsModifier(center: center))
    }
}

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
            .toast(isPresenting: $center.copied, duration: 1.5, offsetY: 20, alert: {
                AlertToast(displayMode: .hud,
                           type: .systemImage("checkmark.circle", .green),
                           titleResource: "Copied!")
            })
            .sensoryFeedback(.lighterImpact, trigger: center.copied) { !$0 && $1 }
            .toast(isPresenting: $center.pasted, duration: 1.5, offsetY: 20, alert: {
                AlertToast(displayMode: .hud,
                           type: .systemImage("checkmark.circle", .green),
                           titleResource: "Pasted!")
            })
            .sensoryFeedback(.lighterImpact, trigger: center.pasted) { !$0 && $1 }
            .toast(isPresenting: .constant(center.refreshingInfos), offsetY: 20, alert: {
                AlertToast(displayMode: .hud,
                           type: .systemImage("arrow.clockwise.circle", .blue),
                           titleResource: "Refreshing infos...")
            })
            .toast(isPresenting: .constant(center.prefetchingImages), offsetY: 20, alert: {
                AlertToast(displayMode: .hud,
                           type: .systemImage("photo.on.rectangle.angled", .blue),
                           titleResource: "Prefetching images...")
            })
            .toast(isPresenting: $center.regularCompleted, offsetY: 20, alert: {
                AlertToast(displayMode: .hud,
                           type: .complete(.green),
                           titleResource: "Done")
            })
            .sensoryFeedback(.success, trigger: center.regularCompleted) { !$0 && $1 }
            .toast(isPresenting: $center.regularFailed, offsetY: 20, alert: {
                AlertToast(displayMode: .hud,
                           type: .error(.red),
                           titleResource: "An error occurred")
            })
            .sensoryFeedback(.error, trigger: center.regularFailed) { !$0 && $1 }
            .toast(item: $center.completionState, offsetY: 20, alert: { completion in
                var alertType: AlertToast.AlertType = .regular
                if let state = completion?.state {
                    switch state {
                    case .completed: alertType = .complete(.green)
                    case .failed: alertType = .error(.red)
                    case .partialComplete: alertType = .regular
                    }
                }
                return AlertToast(displayMode: .hud,
                                  type: alertType,
                                  title: center.completionState?.message)
            })
            .sensoryFeedback(trigger: center.completionState) { _,new in
                guard let state = new?.state else { return nil }
                switch state {
                case .failed: return .error
                case .completed: return .success
                case .partialComplete: return .warning
                }
            }
            .toast(isPresenting: $center.loading,
                   duration: 0,
                   tapToDismiss: false,
                   offsetY: 20) {
                return AlertToast(displayMode: .hud,
                                  type: .systemImage("arrow.clockwise.circle", .blue),
                                  titleResource: "Loading...")
            }
    }
}

extension View {
    /// Attach globalToasts to this view. It is advised to use this modifer on the root view.
    ///
    /// - Note:
    /// Should not be used when a modal view is being presented.
    func globalToasts(center: ToastCenter = .global) -> some View {
        self.modifier(GlobalToastsModifier(center: center))
    }
}

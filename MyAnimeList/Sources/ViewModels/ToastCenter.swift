//
//  ToastCenter.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/4/26.
//

import Foundation
import AlertToast
import SwiftUI

/// This global class is a MainActor-bound singleton that stores properties used to display toasts globally on screen.
/// It is recommended to use this class when toasts need to be triggered from non-UI components or a non-main-thread environment.
@Observable @MainActor
class ToastCenter: ObservableObject {
    static var global: ToastCenter = .init()
    
    var copied: Bool = false
    var pasted: Bool = false
    var refreshingInfos: Bool = false
    var loading: Bool = false
    var prefetchingImages: Bool = false
    var regularCompleted: Bool = false
    var regularFailed: Bool = false
    
    var completionState: CompletedWithMessage? = nil
    
    struct CompletedWithMessage: Identifiable, Equatable {
        var id = UUID()
        var state: State
        var messageResource: LocalizedStringResource
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.state == rhs.state && lhs.messageResource == rhs.messageResource
        }
        
        enum State {
            case completed, failed, partialComplete
        }
        
        static func completed(_ messageResource: LocalizedStringResource) -> Self {
            .init(state: .completed, messageResource: messageResource)
        }
        
        static func failed(_ messageResource: LocalizedStringResource) -> Self {
            .init(state: .failed, messageResource: messageResource)
        }
        
        static func partialComplete(_ messageResource: LocalizedStringResource) -> Self {
            .init(state: .partialComplete, messageResource: messageResource)
        }
        
        static func completed(_ message: String) -> Self {
            .init(state: .completed, messageResource: LocalizedStringResource(stringLiteral: message))
        }
        
        static func failed(_ message: String) -> Self {
            .init(state: .failed, messageResource: LocalizedStringResource(stringLiteral: message))
        }
        
        static func partialComplete(_ message: String) -> Self {
            .init(state: .partialComplete, messageResource: LocalizedStringResource(stringLiteral: message))
        }
    }
}


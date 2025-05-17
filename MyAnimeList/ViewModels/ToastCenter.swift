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
    var refreshingInfos: Bool = false
    var prefetchingImages: Bool = false
    var regularCompleted: Bool = false
    var regularFailed: Bool = false
    
    var completionState: CompletedWithMessage? = nil
    
    struct CompletedWithMessage: Identifiable, Equatable {
        var id = UUID()
        var state: State
        var message: String
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.state == rhs.state && lhs.message == rhs.message
        }
        
        enum State {
            case completed, failed, partialComplete
        }
        
        static func completed(_ message: String) -> Self {
            .init(state: .completed, message: message)
        }
        
        static func failed(_ message: String) -> Self {
            .init(state: .failed, message: message)
        }
        
        static func partialComplete(_ message: String) -> Self {
            .init(state: .partialComplete, message: message)
        }
    }
}


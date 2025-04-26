//
//  ToastCenter.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/4/26.
//

import Foundation
import AlertToast
import SwiftUI

@Observable @MainActor
class ToastCenter: ObservableObject {
    static var global: ToastCenter = .init()
    
    var copied: Bool = false
    var refreshingInfos: Bool = false
    var prefetchingImages: Bool = false
    var regularCompleted: Bool = false
}

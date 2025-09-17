//
//  AlertToast+CustomInit.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/6/19.
//

import Foundation
import AlertToast
import SwiftUI

extension AlertToast {
    init(displayMode: DisplayMode = .alert,
         type: AlertType,
         titleResource: LocalizedStringResource? = nil,
         subTitleResource: LocalizedStringResource? = nil,
         style: AlertStyle? = nil) {
        var title: String?
        var subTitle: String?
        if let titleResource {
            title = String(localized: titleResource)
        }
        if let subTitleResource {
            subTitle = String(localized: subTitleResource)
        }
        self.init(displayMode: displayMode,
                  type: type,
                  title: title,
                  subTitle: subTitle,
                  style: style)
    }
}

//
//  Kingfisher+Extensions.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/6/29.
//

import Foundation
import Kingfisher

extension StorageExpiration {
    /// 90 days.
    static let longTerm: StorageExpiration = .days(90)
    /// 1 day.
    static let shortTerm: StorageExpiration = .days(1)
    /// 180 seconds.
    static let transient: StorageExpiration = .seconds(180)
}

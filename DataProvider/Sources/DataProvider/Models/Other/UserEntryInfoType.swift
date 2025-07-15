//
//  UserEntryInfoType.swift
//  MyAnimeList
//
//  Created by Samuel He on 7/15/25.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

public extension UserEntryInfo {
    static let pasteboardUTType = UTType("com.samuelhe.myanimelist.userentryinfo")!

    /// Copies the UserEntryInfo to the general pasteboard using both a custom UTI and plain text.
    func copyToPasteboard() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UIPasteboard.general.items = [
            [Self.pasteboardUTType.identifier: data,
             UTType.plainText.identifier: self.description]
        ]
    }

    /// Attempts to load UserEntryInfo from the general pasteboard.
    static func fromPasteboard() -> UserEntryInfo? {
        let pasteboard = UIPasteboard.general
        for item in pasteboard.items {
            if let jsonString = item[Self.pasteboardUTType.identifier] as? String,
               let data = jsonString.data(using: .utf8),
               let decoded = try? JSONDecoder().decode(UserEntryInfo.self, from: data) {
                return decoded
            }
        }
        return nil
    }
}

//
//  VerticalDatePickerStyle.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/6/20.
//

import SwiftUI

struct VerticalDatePickerStyle: DatePickerStyle {
    var labelsHidden: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        let minimumDate = configuration.minimumDate ?? .distantPast
        let maximumDate = configuration.maximumDate ?? .distantFuture
        
        VStack(spacing: 3) {
            if !labelsHidden {
                configuration.label
            }
            DatePicker(selection: configuration.$selection, in: minimumDate...maximumDate,
                       displayedComponents: configuration.displayedComponents) { }
                .labelsHidden()
        }
    }
}

extension DatePickerStyle where Self == VerticalDatePickerStyle {
    static func vertical(labelsHidden: Bool = false) -> VerticalDatePickerStyle {
        return VerticalDatePickerStyle(labelsHidden: labelsHidden)
    }
}

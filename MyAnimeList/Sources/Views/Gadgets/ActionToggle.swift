//
//  ActionToggle.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/17.
//

import SwiftUI

struct ActionToggle<Label: View>: View {
    @State var isOn: Bool
    let sensoryFeedback: SensoryFeedback?
    @ViewBuilder let label: () -> Label
    let on: () -> Void
    let off: () -> Void
    
    init(isOn: Bool = false,
         sensoryFeedback: SensoryFeedback? = .selection,
         on: @escaping () -> Void = {},
         off: @escaping () -> Void = {},
         @ViewBuilder label: @escaping () -> Label) {
        self._isOn = .init(initialValue: isOn)
        self.sensoryFeedback = sensoryFeedback
        self.on = on
        self.off = off
        self.label = label
    }
    
    var body: some View {
        Toggle(isOn: $isOn, label: label)
            .onChange(of: isOn) {
                if isOn {
                    on()
                } else {
                    off()
                }
            }
            .sensoryFeedback(trigger: isOn) { _,_ in
                return sensoryFeedback
            }
    }
}

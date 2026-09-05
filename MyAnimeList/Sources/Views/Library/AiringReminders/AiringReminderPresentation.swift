//
//  AiringReminderPresentation.swift
//  AniShelf
//
//  Created by OpenAI Codex on behalf of Samuel He on 2026/9/6.
//

import Foundation

extension AiringReminderSubscription {
    var timingLabel: LocalizedStringResource {
        guard let timingOffsetMinutes else { return "Default" }
        if timingOffsetMinutes == 0 { return "At airtime" }
        if timingOffsetMinutes > 0 { return "\(timingOffsetMinutes) min after" }
        return "\(-timingOffsetMinutes) min before"
    }
}

extension AiringReminderLeadTime {
    var localizedResource: LocalizedStringResource {
        switch self {
        case .atAirtime:
            "At airtime"
        case .fiveMinutes:
            "5 minutes before"
        case .fifteenMinutes:
            "15 minutes before"
        case .thirtyMinutes:
            "30 minutes before"
        case .oneHour:
            "1 hour before"
        case .fiveMinutesAfter:
            "5 minutes after"
        case .fifteenMinutesAfter:
            "15 minutes after"
        case .thirtyMinutesAfter:
            "30 minutes after"
        case .oneHourAfter:
            "1 hour after"
        }
    }
}

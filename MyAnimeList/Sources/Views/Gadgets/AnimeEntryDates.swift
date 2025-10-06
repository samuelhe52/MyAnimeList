//
//  AnimeEntryDates.swift
//  MyAnimeList
//
//  Created by Samuel He on 7/19/25.
//

import DataProvider
import SwiftUI

struct AnimeEntryDates: View {
    var entry: AnimeEntry
    var labelsHidden: Bool = false

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    var body: some View {
        HStack(spacing: 12) {
            Spacer()
            VStack(spacing: 4) {
                if !labelsHidden {
                    Text("Date Started")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let dateStarted = entry.dateStarted {
                    Text(dateStarted, formatter: dateFormatter)
                } else {
                    Text(verbatim: "N/A")
                }
            }
            Image(systemName: "ellipsis")
                .alignmentGuide(VerticalAlignment.center) { d in
                    labelsHidden ? d[VerticalAlignment.center] : -6
                }
            VStack(spacing: 4) {
                if !labelsHidden {
                    Text("Date Finished")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let dateFinished = entry.dateFinished {
                    Text(dateFinished, formatter: dateFormatter)
                } else {
                    Text(verbatim: "N/A")
                }
            }
            Spacer()
        }
        .foregroundStyle(.secondary)
    }
}

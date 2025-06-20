//
//  AnimeEntryEditor.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/6/20.
//

import SwiftUI
import DataProvider
import SwiftData
import SHContainers

typealias WatchedStatus = AnimeEntry.WatchStatus

struct AnimeEntryEditor: View {
    @Environment(\.dataHandler) var dataHandler
    @Environment(\.locale) var locale
    @Bindable var entry: AnimeEntry
    
    private var dateStartedBinding: Binding<Date> {
        .init(get: {
            entry.dateStarted ?? .now
        }, set: {
            entry.dateStarted = $0
        })
    }
    
    private var dateFinishedBinding: Binding<Date> {
        .init(get: {
            entry.dateFinished ?? .now
        }, set: {
            entry.dateFinished = $0
        })
    }
    
    var body: some View {
        SHForm {
            SHSection("Watch Status", alignment: .center) {
                AnimeEntryWatchedStatusPicker(entry: entry)
                    .pickerStyle(.segmented)
                HStack {
                    Spacer()
                    DatePicker(selection: dateStartedBinding, displayedComponents: [.date]) {
                        Text("Date Started")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }.datePickerStyle(VerticalDatePickerStyle())
                    Image(systemName: "ellipsis")
                        .alignmentGuide(VerticalAlignment.center) { _ in -6 }
                        .foregroundStyle(.secondary)
                    DatePicker(selection: dateFinishedBinding, displayedComponents: [.date]) {
                        Text("Date Finished")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }.datePickerStyle(VerticalDatePickerStyle())
                    Spacer()
                }
            }
        }
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { print(locale.identifier) }
    }
}

struct AnimeEntryWatchedStatusPicker: View {
    @Bindable var entry: AnimeEntry
    @Environment(\.dataHandler) var dataHandler
    
    var body: some View {
        Picker(selection: $entry.watchStatus) {
            Text("Plan to Watch").tag(WatchedStatus.planToWatch)
            Text("Watching").tag(WatchedStatus.watching)
            Text("Watched").tag(WatchedStatus.watched)
        } label: { }
    }
}

#Preview {
    @Previewable @State var dataProvider = DataProvider.forPreview
    @Previewable @State var entry: AnimeEntry = .template(id: 1)
    AnimeEntryEditor(entry: entry)
        .environment(\.dataHandler, dataProvider.dataHandler)
        .onAppear {
            dataProvider.generateEntriesForPreview()
            let entries = try? dataProvider.getAllModels(ofType: AnimeEntry.self)
            entry = entries?.first ?? .template(id: 124)
        }
}

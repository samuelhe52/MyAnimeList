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
import AlertToast

typealias WatchedStatus = AnimeEntry.WatchStatus

struct AnimeEntryEditor: View {
    @Environment(\.dataHandler) var dataHandler
    @Environment(\.undoManager) var undoManager
    @Environment(\.locale) var locale
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Bindable var entry: AnimeEntry
    
    @State var showPosterSelectionView: Bool = false
    @State var showFavoritedToast: Bool = false
    
    init(entry: AnimeEntry) {
        self.entry = entry
    }
    
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
    
    @State var showNavigationTitle: Bool = false
    
    var body: some View {
        SHForm(alignment: .leading) {
            navigationHeader
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
        .navigationTitle(showNavigationTitle ? entry.name : "")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done", action: dismissAction)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showPosterSelectionView) {
            NavigationStack {
                PosterSelectionView(entry: entry)
                    .navigationTitle("Change Poster")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                showPosterSelectionView = false
                            }
                        }
                    }
            }
        }
        .toast(isPresenting: $showFavoritedToast, duration: 1.5, offsetY: 35, alert: {
            let favoritedMessage: LocalizedStringResource = "Favorited"
            let unFavoritedMessage: LocalizedStringResource = "Unfavorited"
            return AlertToast(displayMode: .hud,
                       type: .systemImage(entry.favorite ? "star.fill" : "star.slash.fill", .primary),
                       titleResource: entry.favorite ? favoritedMessage : unFavoritedMessage)
        })
        .sensoryFeedback(.lighterImpact, trigger: entry.favorite)
    }
    
    var navigationHeader: some View {
        HStack(alignment: .top) {
            Menu {
                Button("Change Poster", systemImage: "photo") {
                    showPosterSelectionView = true
                }
            } label: {
                PosterView(url: entry.posterURL, diskCacheExpiration: .days(90))
                    .aspectRatio(contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 6))
                    .frame(width: 120)
            }
            .menuStyle(.borderlessButton)
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(entry.name)
                            .font(.title2)
                            .onScrollVisibilityChange { visible in
                                showNavigationTitle = !visible
                            }
                        if let onAirDate = entry.onAirDate {
                            Text(monthAndYearDateFormatter.string(from: onAirDate))
                                .font(.caption)
                                .padding(.bottom, 5)
                        }
                    }
                    Spacer()
                    Button {
                        withAnimation(.spring(duration: 0.2)) {
                            entry.favorite.toggle()
                            showFavoritedToast = true
                        }
                    } label: {
                        Image(systemName: entry.favorite ? "star.circle.fill" : "star.circle")
                            .font(.title2)
                    }
                    .buttonStyle(.borderless)
                }
                if let overview = entry.overview {
                    Text(overview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(8)
                }
            }
        }
    }
    
    var monthAndYearDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "MMM YYYY"
        return formatter
    }
    
    func dismissAction() {
        do {
            try modelContext.save()
        } catch {
            ToastCenter.global.completionState = .failed(error.localizedDescription)
        }
        dismiss()
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
    NavigationStack {
        AnimeEntryEditor(entry: entry)
            .environment(\.dataHandler, dataProvider.dataHandler)
            .onAppear {
                dataProvider.generateEntriesForPreview()
                let entries = try? dataProvider.getAllModels(ofType: AnimeEntry.self)
                entry = entries?.first ?? .template(id: 124)
            }
    }
}

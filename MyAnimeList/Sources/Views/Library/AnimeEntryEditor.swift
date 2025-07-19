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
import os

typealias WatchedStatus = AnimeEntry.WatchStatus
fileprivate let logger = Logger(subsystem: .bundleIdentifier, category: "AnimeEntryEditor")

struct AnimeEntryEditor: View {
    @Environment(\.dataHandler) var dataHandler
    @Environment(\.undoManager) var undoManager
    @Environment(\.locale) var locale
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Bindable var entry: AnimeEntry
    
    @State private var showPosterSelectionView: Bool = false
    @State private var showFavoritedToast: Bool = false
    @State private var showNavigationTitle: Bool = false
    @State private var originalUserInfo: UserEntryInfo
    @State private var showCancelEditsConfirmation: Bool = false
        
    init(entry: AnimeEntry) {
        self.entry = entry
        self._originalUserInfo = .init(initialValue: UserEntryInfo(for: entry))
    }
    
    private var dateStartedBinding: Binding<Date> {
        Binding(get: {
            entry.dateStarted ?? .now
        }, set: {
            entry.dateStarted = $0
        })
    }
    
    private var dateFinishedBinding: Binding<Date> {
        Binding(get: {
            entry.dateFinished ?? .now
        }, set: {
            entry.dateFinished = $0
            if $0 < .now {
                entry.watchStatus = .watched
            }
        })
    }
    
    private var watchedStatusBinding: Binding<WatchedStatus> {
        Binding(get: {
            entry.watchStatus
        }, set: {
            entry.watchStatus = $0
            switch $0 {
            case .watched: entry.dateFinished = .now
            case .watching: entry.dateStarted = .now
            default: break
            }
        })
    }
        
    var body: some View {
        SHForm(alignment: .leading) {
            navigationHeader
            SHSection("Notes") {
                PlaceholderTextEditor(text: $entry.notes,
                                      placeholder: "Write some thoughts...")
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .frame(height: 150)
            }
            SHSection("Watch Status", alignment: .center) {
                AnimeEntryWatchedStatusPicker(status: watchedStatusBinding)
                    .pickerStyle(.segmented)
                AnimeEntryDatePickers(dateStarted: dateStartedBinding,
                                      dateFinished: dateFinishedBinding)
            }
        }
        .navigationTitle(showNavigationTitle ? entry.name : "")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: dismissAction)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { showCancelEditsConfirmation = true }
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
        .confirmationDialog("Discard all changes?", isPresented: $showCancelEditsConfirmation) {
            Button("Discard", role: .destructive) {
                do {
                    entry.updateUserInfo(from: originalUserInfo)
                    try modelContext.save()
                } catch {
                    ToastCenter.global.completionState = .failed(error.localizedDescription)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
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
    
    private var navigationHeader: some View {
        HStack(alignment: .top) {
            Menu {
                Button("Change Poster", systemImage: "photo") {
                    showPosterSelectionView = true
                }
            } label: {
                PosterView(url: entry.posterURL, diskCacheExpiration: .longTerm)
                    .aspectRatio(contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 6))
                    .frame(width: 120)
                    .overlay(alignment: .bottomTrailing) {
                        AnimeTypeIndicator(type: entry.type, padding: 3)
                            .font(.caption2)
                    }
            }
            .menuStyle(.borderlessButton)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading) {
                        name
                        seasonNumberAndDate
                    }
                    Spacer()
                    favoriteButton
                }
                if let overview = entry.displayOverview {
                    Text(overview)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(height: 140)
                }
            }
        }
    }
    
    @ViewBuilder
    private var seasonNumberAndDate: some View {
        HStack(alignment: .center) {
            if let seasonNumber = entry.seasonNumber {
                Text("Season \(seasonNumber)")
            }
            if let onAirDate = entry.onAirDate {
                Text(monthAndYearDateFormatter.string(from: onAirDate))
            }
        }
        .font(.caption)
    }
    
    @ViewBuilder
    private var name: some View {
        Text(entry.displayName)
            .font(.headline)
            .onScrollVisibilityChange(threshold: 0.2) { visible in
                showNavigationTitle = !visible
            }
            .lineLimit(1)
    }
    
    private var favoriteButton: some View {
        EntryFavoriteButton(favorited: entry.favorite) {
            withAnimation(.spring(duration: 0.2)) {
                dataHandler?.toggleFavorite(entry: entry)
                showFavoritedToast = true
            }
        }
        .font(.title2)
        .buttonStyle(.borderless)
        .labelStyle(.iconOnly)
    }
    
    private var monthAndYearDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY.MM"
        return formatter
    }
    
    private var parentSeriesName: String? { entry.parentSeriesEntry?.name }
    
    private func dismissAction() {
        do {
            try modelContext.save()
        } catch {
            ToastCenter.global.completionState = .failed(error.localizedDescription)
        }
        dismiss()
    }
}

struct AnimeEntryWatchedStatusPicker: View {
    @Binding var status: WatchedStatus
    @Environment(\.dataHandler) var dataHandler
    
    var body: some View {
        Picker(selection: $status) {
            Text("Plan to Watch").tag(WatchedStatus.planToWatch)
            Text("Watching").tag(WatchedStatus.watching)
            Text("Watched").tag(WatchedStatus.watched)
        } label: { }
    }
}

struct AnimeEntryDatePickers: View {
    @Binding var dateStarted: Date
    @Binding var dateFinished: Date
    
    var body: some View {
        HStack {
            Spacer()
            DatePicker(selection: $dateStarted,
                       in: Date.distantPast...dateFinished,
                       displayedComponents: [.date]) {
                Text("Date Started")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }.datePickerStyle(VerticalDatePickerStyle())
            Image(systemName: "ellipsis")
                .alignmentGuide(VerticalAlignment.center) { _ in -6 }
                .foregroundStyle(.secondary)
            DatePicker(selection: $dateFinished,
                       in: dateStarted...Date.distantFuture,
                       displayedComponents: [.date]) {
                Text("Date Finished")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }.datePickerStyle(VerticalDatePickerStyle())
            Spacer()
        }
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

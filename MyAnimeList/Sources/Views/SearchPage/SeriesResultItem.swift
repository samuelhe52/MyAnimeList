//
//  SeriesResultItem.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/11.
//

import SwiftUI
import DataProvider

struct SeriesResultItem: View {
    @Environment(SearchService.self) var service
    let series: BasicInfo
    @State private var resultOption: ResultOption = .series
    @State private var seasons: [BasicInfo] = []
        
    var body: some View {
        HStack {
            PosterView(url: series.posterURL)
                .frame(width: 80, height: 120)
            VStack(alignment: .leading) {
                infosAndSelection
                resultOptionsView
            }
        }
        .onChange(of: resultOption) {
            if resultOption == .season && seasons.isEmpty {
                Task { try await fetchSeasons() }
            }
        }
    }

    @ViewBuilder
    private var infosAndSelection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                Text(series.name)
                    .bold()
                    .lineLimit(1)
                if let date = series.onAirDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .padding(.bottom, 1)
                }
            }
            Spacer()
            selectionIndicator
        }
        Text(series.overview ?? "No overview available")
            .font(.caption2)
            .foregroundStyle(.gray)
            .lineLimit(3)
    }
    
    @ViewBuilder
    private var resultOptionsView: some View {
        Picker("", selection: $resultOption) {
            ForEach(ResultOption.allCases, id: \.hashValue) { option in
                switch option {
                case .series: Text("Series").tag(option)
                case .season: Text("Season").tag(option)
                }
            }
        }
        .pickerStyle(.segmented)
    }
    
    @ViewBuilder
    private var selectionIndicator: some View {
        if resultOption == .series {
            ActionToggle(on: {
                service.register(info: series)
            }, off: {
                service.unregister(info: series)
            }, label: {
                Image(systemName: "checkmark")
            })
            .toggleStyle(.button)
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .frame(height: 0)
            .onDisappear { service.unregister(info: series) }
        } else {
            SeasonSelector(seasons: seasons, register: service.register, unregister: service.unregister)
                .padding(.trailing, 7)
        }
    }
    private func fetchSeasons() async throws {
        let fetcher = service.fetcher
        let fetchedSeasons = try await fetcher.tvSeries(series.id, language: .japanese).seasons
        if let fetchedSeasons {
            let seasonResults = try await withThrowingTaskGroup(of: BasicInfo.self) { group in
                for season in fetchedSeasons {
                    group.addTask {
                        let seriesBackdropURL = try await fetcher.tmdbClient.imagesConfiguration.backdropURL(for: series.backdropURL)
                        let logoURL = try await fetcher.tmdbClient.imagesConfiguration.logoURL(for: series.logoURL)
                        let seasonResult = try await season.basicInfo(client: fetcher.tmdbClient,
                                                                      backdropURL: seriesBackdropURL,
                                                                      logoURL: logoURL,
                                                                      linkToDetails: series.linkToDetails,
                                                                      parentSeriesID: series.tmdbID)
                        return seasonResult
                    }
                }
                var results: [BasicInfo] = []
                for try await result in group {
                    results.append(result)
                }
                return results
            }
            withAnimation {
                seasons = seasonResults.sorted {
                    let seasonNumber1 = $0.type.seasonNumber ?? 0
                    let seasonNumber2 = $1.type.seasonNumber ?? 0
                    return seasonNumber1 < seasonNumber2
                }
            }
        }
    }
    
    enum ResultOption: CaseIterable, Equatable {
        case series
        case season
    }
}

fileprivate struct SeasonSelector: View {
    let seasons: [BasicInfo]
    var register: (BasicInfo) -> Void
    var unregister: (BasicInfo) -> Void
    @State private var selectedSeasonIDs: Set<Int> = []
    
    var body: some View {
        Menu {
            ForEach(seasons, id: \.tmdbID) { season in
                let selected = selectedSeasonIDs.contains(season.tmdbID)
                if let seasonNumber = season.type.seasonNumber {
                    Button {
                        if !selected {
                            register(season)
                            selectedSeasonIDs.insert(season.tmdbID)
                        } else {
                            unregister(season)
                            selectedSeasonIDs.remove(season.tmdbID)
                        }
                    } label: {
                        let title = seasonNumber != 0 ? "Season \(seasonNumber)" : "Specials"
                        if !selected {
                            Text(title)
                        } else {
                            Label(title, systemImage: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Text("\(selectedSeasonIDs.count)")
                .font(.system(size: 18, design: .monospaced))
        }
        .padding(9)
        .background(in: .circle)
        .backgroundStyle(selectedSeasonIDs.isEmpty ? Color(uiColor: .systemGray5) : .blue.opacity(0.2))
        .frame(height: 0)
        .animation(.smooth(duration: 0.2), value: selectedSeasonIDs)
        .menuActionDismissBehavior(.disabled)
        .sensoryFeedback(.selection, trigger: selectedSeasonIDs)
        .onDisappear {
            for season in seasons {
                unregister(season)
            }
        }
    }
}

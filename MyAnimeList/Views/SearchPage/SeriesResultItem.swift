//
//  SeriesResultItem.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/11.
//

import SwiftUI

struct SeriesResultItem: View {
    let series: SearchResult
    @Binding var resultsToSubmit: Set<SearchResult>
    let fetcher: InfoFetcher
    
    @State private var resultOption: ResultOption = .series
    @State private var seasons: [SearchResult] = []
    @State private var addToResults: Bool = false
        
    var body: some View {
        HStack {
            PosterView(url: series.posterURL)
                .frame(width: 80, height: 120)
            VStack(alignment: .leading) {
                infosAndToggles
                resultOptionsView
            }
        }
        .onChange(of: resultOption) {
            if resultOption == .season && seasons.isEmpty {
                Task { try await fetchSeasons() }
            }
            addToResults = false
        }
        .onChange(of: addToResults) {
            if addToResults {
                if resultOption == .series {
                    resultsToSubmit.insert(series)
                }
            } else {
                resultsToSubmit.remove(series)
                for season in seasons {
                    resultsToSubmit.remove(season)
                }
            }
        }
        .animation(.default, value: resultOption)
        .sensoryFeedback(.selection, trigger: addToResults) { _,_ in
            return resultOption == .series
        }
    }

    @ViewBuilder
    private var infosAndToggles: some View {
        HStack{
            Text(series.name)
                .bold()
                .lineLimit(1)
            Spacer()
            if resultOption == .series {
                Toggle(isOn: $addToResults) {
                    Image(systemName: "checkmark")
                }
                .toggleStyle(.button)
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .frame(height: 0)
            } else {
                SeasonSelector(seasons: seasons,
                               resultsToSubmit: $resultsToSubmit,
                               addToResults: $addToResults)
            }
        }
        if let date = series.onAirDate {
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .padding(.bottom, 1)
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
    
    private func fetchSeasons() async throws {
        let fetchedSeasons = try await fetcher.tvSeries(series.id, language: .japanese).seasons
        if let fetchedSeasons {
            let seasonResults = try await withThrowingTaskGroup(of: SearchResult.self) { group in
                for season in fetchedSeasons {
                    group.addTask {
                        let seriesBackdropURL = try await fetcher.tmdbClient.imagesConfiguration.backdropURL(for: series.backdropURL)
                        let logoURL = try await fetcher.tmdbClient.imagesConfiguration.logoURL(for: series.logoURL)
                        let seasonResult = try await season.basicInfo(client: fetcher.tmdbClient,
                                                                      backdropURL: seriesBackdropURL,
                                                                      logoURL: logoURL,
                                                                      linkToDetails: series.linkToDetails,
                                                                      parentSeriesID: series.tmdbID) as SearchResult
                        return seasonResult
                    }
                }
                var results: [SearchResult] = []
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
    let seasons: [SearchResult]
    @Binding var resultsToSubmit: Set<SearchResult>
    @Binding var addToResults: Bool
    @State var selectedSeasonIDs: Set<Int> = []
    
    var body: some View {
        return Menu("\(selectedSeasonIDs.count) selected") {
            ForEach(seasons, id: \.tmdbID) { season in
                let selected = selectedSeasonIDs.contains(season.tmdbID)
                if let seasonNumber = season.type.seasonNumber {
                    Button {
                        if !selected {
                            resultsToSubmit.insert(season)
                            selectedSeasonIDs.insert(season.tmdbID)
                            addToResults = true
                        } else {
                            resultsToSubmit.remove(season)
                            selectedSeasonIDs.remove(season.tmdbID)
                            if selectedSeasonIDs.isEmpty {
                                addToResults = false
                            }
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
        }
        .animation(nil, value: resultsToSubmit)
        .menuActionDismissBehavior(.disabled)
        .sensoryFeedback(.selection, trigger: selectedSeasonIDs)
    }
}

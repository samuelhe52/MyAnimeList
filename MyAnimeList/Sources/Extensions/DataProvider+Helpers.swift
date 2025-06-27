//
//  AnimeEntry+Helpers.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/24.
//

import DataProvider
import SwiftData
import Foundation

extension AnimeEntry {
    /// Creates a new AnimeEntry instance from BasicInfo.
    ///
    /// - Parameter info: The BasicInfo containing the anime details.
    convenience init(fromInfo info: BasicInfo) {
        self.init(name: info.name,
                  overview: info.overview,
                  onAirDate: info.onAirDate,
                  type: info.type,
                  linkToDetails: info.linkToDetails,
                  posterURL: info.posterURL,
                  backdropURL: info.backdropURL,
                  tmdbID: info.tmdbID,
                  dateSaved: .now)
    }
    
    /// Updates the anime entry with new information from BasicInfo.
    ///
    /// - Parameter info: The BasicInfo containing updated anime details.
    /// - Note: Only updates properties that have non-nil values in the info parameter.
    func update(from info: BasicInfo) {
        name = info.name
        overview = info.overview ?? self.overview
        linkToDetails = info.linkToDetails ?? self.linkToDetails
        posterURL = info.posterURL ?? self.posterURL
        backdropURL = info.backdropURL ?? self.backdropURL
        onAirDate = info.onAirDate ?? self.onAirDate
        type = info.type
        tmdbID = info.tmdbID
    }
    
    /// Converts the AnimeEntry to BasicInfo.
    var basicInfo: BasicInfo {
        BasicInfo(name: name,
                  overview: overview,
                  posterURL: posterURL,
                  backdropURL: backdropURL,
                  tmdbID: tmdbID,
                  onAirDate: onAirDate,
                  linkToDetails: linkToDetails,
                  type: type)
    }
}

extension DataProvider {
    func generateEntriesForPreview() {
        // Ensure we're in preview
        guard inMemory else { return }
        do {
            let frierenEntry = AnimeEntry(
                name: "葬送のフリーレン",
                overview: "勇者ヒンメルたちと共に、10年に及ぶ冒険の末に魔王を打ち倒し、世界に平和をもたらした魔法使いフリーレン。千年以上生きるエルフである彼女は、ヒンメルたちと再会の約束をし、独り旅に出る。それから50年後、フリーレンはヒンメルのもとを訪ねるが、50年前と変わらぬ彼女に対し、ヒンメルは老い、人生は残りわずかだった。その後、死を迎えたヒンメルを目の当たりにし、これまで“人を知る”ことをしてこなかった自分を痛感し、それを悔いるフリーレンは、“人を知るため”の旅に出る。その旅路には、さまざまな人との出会い、さまざまな出来事が待っていた―。",
                onAirDate: .now,
                type: .series,
                linkToDetails: URL(string: "https://frieren-anime.jp/"),
                posterURL: URL(string: "https://image.tmdb.org/t/p/original/dDRiOkCBCkd7w6ysMFr39G16opQ.jpg"),
                backdropURL: URL(string: "https://image.tmdb.org/t/p/original/96RT2A47UdzWlUfvIERFyBsLhL2.jpg"),
                tmdbID: 209867,
                dateSaved: .now,
                dateStarted: nil,
                dateFinished: nil,
              )
            try dataHandler.newEntry(frierenEntry)
            try dataHandler.newEntry(AnimeEntry(name: "CLANNAD Season 1",
                                                type: .season(seasonNumber: 1, parentSeriesID: 24835),
                                                tmdbID: 35033))
            try dataHandler.newEntry(AnimeEntry(name: "Koe no katachi", type: .movie, tmdbID: 378064))
        } catch {
            print("Error generating preview entries: \(error)")
        }
    }
}

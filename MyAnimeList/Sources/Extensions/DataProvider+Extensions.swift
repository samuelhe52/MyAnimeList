//
//  DataProvider+Extensions.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/24.
//

import DataProvider
import SwiftData
import Foundation

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

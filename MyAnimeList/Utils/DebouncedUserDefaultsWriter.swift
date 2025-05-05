//
//  DebouncedUserDefaultsWriter.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/3.
//

import Foundation
import Combine

class DebouncedIntUserDefaultsWriter {
    private var cancellable: AnyCancellable?
    
    init<P: Publisher>(publisher: P, forKey key: String, delay: TimeInterval = 0.5) where P.Output == Int?, P.Failure == Never {
        let queue = DispatchQueue(label: "com.samuelhe.MyAnimeList.userdefaults.intwriter", qos: .background)
        
        self.cancellable = publisher
            .debounce(for: .seconds(delay), scheduler: queue)
            .sink { value in
                UserDefaults.standard.set(value, forKey: key)
            }
    }
}

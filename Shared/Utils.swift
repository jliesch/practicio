//
//  Utils.swift
//  Practicio
//
//  Created by Jesse Liesch on 8/5/22.
//

import Foundation

struct Constants {
    static var minFrequency = 0.1
    static var avgFrequency = 1.0
    static var maxFrequency = 10.0
    static var defaultItemAge = 7
}

func ItemAge(_ from: Date) -> Int {
    let to = Date()
    let fromDate = Calendar.current.startOfDay(for: from)
    let toDate = Calendar.current.startOfDay(for: to)
    let numberOfDays = Calendar.current.dateComponents([.day], from: fromDate, to: toDate)
    
    return numberOfDays.day ?? 0
}

func ItemScore(_ item: Item) -> Double {
    if item.relativeFrequency < Constants.minFrequency {
        item.relativeFrequency = Constants.minFrequency
    }
    var age: Int
    if let lp = item.lastPractice {
        age = ItemAge(lp)
    } else {
        age = Constants.defaultItemAge
    }
    return Double(age) / item.relativeFrequency
}

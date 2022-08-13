//
//  Utils.swift
//  Practicio
//
//  Created by Jesse Liesch on 8/5/22.
//

import Foundation

func ItemAge(_ from: Date) -> Int {
    let to = Date()
    let fromDate = Calendar.current.startOfDay(for: from)
    let toDate = Calendar.current.startOfDay(for: to)
    let numberOfDays = Calendar.current.dateComponents([.day], from: fromDate, to: toDate)
    
    return numberOfDays.day ?? Constants.defaultItemAge
}

func ItemScore(_ item: Item) -> Double {
    // Clamp frequency to min/max as a sanity check
    let freq = min(max(item.relativeFrequency, Constants.minFrequency), Constants.maxFrequency)
    var age: Int
    if let lp = item.lastPractice {
        age = ItemAge(lp)
    } else {
        age = Constants.defaultItemAge
    }
    return Double(age) / freq
}

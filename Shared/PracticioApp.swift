//
//  PracticioApp.swift
//  Shared
//
//  Created by Jesse Liesch on 8/5/22.
//

import SwiftUI

// Sort order for practice items
enum SortOrder: CaseIterable {
    case alphabetical, lastPracticed, frequency, score
}

struct Constants {
    static var minFrequency = 0.1
    static var avgFrequency = 1.0
    static var maxFrequency = 10.0
    
    // Ranking for practice items that have never been practiced
    static var defaultItemAge = 7
}

class AppState: ObservableObject {
    @Published var selectedCategory: Category? = nil
    @Published var selectedItem: Item? = nil
    @Published var sortOrder: SortOrder = .score

    // changeCounter is used to force views to update when the underlying
    // storage may have changed but thew view is not aware of it.
    @Published var changedCounter: Int = 0
}

extension Text {
    func myTitle() -> Text {
        return self.font(.title2).foregroundColor(Color("TextColor"))
    }

    func myText() -> Text {
        return self.foregroundColor(Color("TextColor"))
    }
}

@main
struct PracticioApp: App {
    @StateObject private var dataController = DataController()
    @State private var state = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(state)
        }
    }
}

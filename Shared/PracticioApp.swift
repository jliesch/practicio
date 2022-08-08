//
//  PracticioApp.swift
//  Shared
//
//  Created by Jesse Liesch on 8/5/22.
//

import SwiftUI

enum SortOrder: CaseIterable {
    case alphabetical, lastPracticed, frequency, score
}

class AppState: ObservableObject {
    @Published var selectedCategory: Category? = nil
    @Published var selectedItem: Item? = nil
    @Published var changedCounter: Int = 0
    @Published var sortOrder: SortOrder = .score
}

extension Text {
    func myTitle() -> Text {
        return self.font(.title).foregroundColor(Color("TextColor"))
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

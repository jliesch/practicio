//
//  ContentView.swift
//  Shared
//
//  Created by Jesse Liesch on 8/5/22.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var state: AppState
    
    var body: some View {
        if let category = state.selectedCategory {
            CategoryView(category: category)
        } else {
            CategoriesView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//
//  CategoriesView.swift
//  Practicio
//
//  Created by Jesse Liesch on 8/5/22.
//

import SwiftUI

struct CategoriesView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)])
    var categories: FetchedResults<Category>
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            Text("Categories")
                .myTitle()
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("HeaderColor"))

            if categories.isEmpty {
                Spacer()
                Text("Add your first category (examples: Exercises, New Pieces, Repertoire, etc.)").myText().padding()
            } else {
                List {
                    ForEach(Array(categories.enumerated()), id: \.1.id) { (index, category) in
                        let backgroundColor: Color = index % 2 == 0 ? .white.opacity(0.0) : Color("StripeColor")
                        Button() {
                            state.selectedCategory = category
                        } label: {
                            Text(category.name ?? "Unknown")
                                .myText()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding([.top, .bottom], 15.0)
                        .listRowBackground(backgroundColor)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                moc.delete(category)
                                try? moc.save()
                                state.changedCounter += 1
                            } label: {
                              Label("Delete", systemImage: "trash")
                            }
                          }
#if os(macOS)
                        .foregroundColor(Color(NSColor.textColor))
#else
                        .foregroundColor(.primary)
#endif
                    }
                    
                }.listStyle(.plain)
            }
        
            Spacer()

            Button() {
                let category = Category(context: moc)
                category.id = UUID()
                category.name = "New Category"
                try? moc.save()
                state.selectedCategory = category
            } label: {
                VStack {
                    Image(systemName: "plus.rectangle.on.folder").font(Font.system(.largeTitle))
                    Text("Add Category").myText().padding(3)
                }
            }.padding()
        }
    }
}

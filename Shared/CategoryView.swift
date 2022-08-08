//
//  CategoryView.swift
//  Practicio
//
//  Created by Jesse Liesch on 8/5/22.
//

import CoreData
import SwiftUI

struct CategoryView: View {
    @EnvironmentObject var state: AppState
    let category: Category

    @State var title: String = ""
    @State var deleteCategory = false
    @Environment(\.managedObjectContext) var moc
        
    @FocusState private var categoryTitleInFocus: Bool
    
    var items: [Item] {
        return category.items?.allObjects as? [Item] ?? []
    }
    @State var sortedItems: [Item] = []
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    TextField(title, text: $title)
                        .multilineTextAlignment(.center)
                        .focused($categoryTitleInFocus)
                        .font(.title)
                        .foregroundColor(Color("TextColor")).padding()

                    HStack(alignment: .center) {
                        Button() {
                            state.selectedCategory = nil
                            state.selectedItem = nil
                        } label: {
                            Image(systemName: "arrowshape.turn.up.backward").font(Font.system(.title))
                        }.padding()

                        Spacer()

                        Menu {
                            Picker("Flavor", selection: $state.sortOrder) {
                                Label("Sort Alphabetically", systemImage: "textformat.abc").tag(SortOrder.alphabetical)
                                Label("Sort by Last Practiced", systemImage: "timer").tag(SortOrder.lastPracticed)
                                Label("Sort by Frequency", systemImage: "waveform").tag(SortOrder.frequency)
                                Label("Sort by Ranking", systemImage: "list.number").tag(SortOrder.score)
                            }
                            
                            Button() {
                                deleteCategory = true
                            } label: {
                                Image(systemName: "trash").font(Font.system(.title))
                                Text("Delete Category").myText()
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle").font(Font.system(.title))
                        }
                        .buttonStyle(BorderlessButtonStyle())  // Prevent multiple buttons from being clicked
                        .padding()
                    }
                }.background(Color("HeaderColor"))

                if title == "New Category" {
                    Spacer()
                    
                    Text("Set the name for this practice category by tapping on \"New Category\"")
                        .myText()
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                }
                if items.isEmpty {
                    Spacer()
                    
                    Text("Add your first practice item (examples: C Major Scale, Mary Had a Little Lamb, etc.)")
                        .myText()
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                }

                let (mediumScore, highScore) = scoreColors()
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(sortedItems.enumerated()), id: \.1.id) { (index, item) in
                            // Make sure the item is still available. It may have been deleted.
                            if item.name != nil {
                                let backgroundColor: Color = index % 2 == 0 ? .white.opacity(0.0) : Color("StripeColor")

                                HStack(alignment: .center) {
                                    let practicedToday = ItemAge(item.lastPractice ?? .distantPast) == 0
                                    if !practicedToday {
                                        Button() {
                                            item.lastPractice = Date()
                                            try? moc.save()
                                            withAnimation(.easeIn) {
                                                sortedItems = sortItems()
                                            }
                                        } label: {
                                            Image(systemName: "circle").font(Font.system(.title2))
                                        }.buttonStyle(BorderlessButtonStyle())  // Prevent multiple buttons from being clicked
                                    } else {
                                        Image(systemName: "checkmark.circle")
                                            .font(Font.system(.title2))
                                            .foregroundColor(.blue)
                                    }

                                    let color = itemColor(item: item, mediumScore: mediumScore, highScore: highScore)
                                    Button() {
                                        if state.selectedItem != nil && item.id == state.selectedItem!.id {
                                            state.selectedItem = nil
                                        } else {
                                            state.selectedItem = item
                                        }
                                    } label: {
                                        Text(item.name ?? "Unknown")
                                            .foregroundColor(color)
                                            .myText()
                                            .strikethrough(practicedToday)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())  // Prevent multiple buttons from being clicked
                                    .padding([.leading])
                                }
                                .padding()
                                .background(backgroundColor)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button() {
                    let item = Item(context: moc)
                    item.id = UUID()
                    item.categoryId = category.id
                    item.name = "New Item"
                    item.category = category
                    try? moc.save()
                    state.selectedItem = item
                    state.changedCounter += 1
                } label: {
                    VStack {
                        Image(systemName: "plus.square.on.square").font(Font.system(.largeTitle))
                        Text("Add Practice Item")
                            .myText()
                            .padding(3)
                    }
                }.padding()
            }
        }.onAppear {
            title = category.name ?? "New Category"
            if title == "New Category" {
                categoryTitleInFocus = true
            }
        }.onChange(of: title) { newTitle in
            category.name = newTitle
            try? moc.save()
        }.onChange(of: state.changedCounter) { newCounter in
            withAnimation(.easeIn) {
                sortedItems = sortItems()
            }
        }.onChange(of: state.sortOrder) { newOrder in
            withAnimation(.easeIn) {
                sortedItems = sortItems()
            }
        }.sheet(isPresented: Binding<Bool>(get: { state.selectedItem != nil }, set: { _ in }),
                onDismiss: { state.selectedItem = nil }) {
            ForEach(items, id: \.id) { item in
                if item.id == state.selectedItem!.id {
                    ItemView(item: item)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10.0)
                        .animation(.easeInOut, value: state.selectedItem)  // Not working
                }
            }
        }.alert(isPresented: $deleteCategory) {
            Alert(title: Text("Delete Category").myText(),
                  message: Text("Delete this category. All items in this category will be deleted. Are you sure?").myText(),
                  primaryButton: .default(Text("Cancel")) { deleteCategory = false },
                  secondaryButton: .destructive(Text("Delete")) {
                deleteCategory = false
                moc.delete(category)
                try? moc.save()
                state.selectedCategory = nil
                state.selectedItem = nil
                withAnimation(.easeIn) {
                    sortedItems = sortItems()
                }
            })
        }.onAppear {
            sortedItems = sortItems()
        }
    }
    
    func sortItems() -> [Item] {
        switch state.sortOrder {
            case .alphabetical:
                return items.sorted(by: { $0.name ?? "" < $1.name ?? "" })
            case  .lastPracticed:
                return items.sorted(by: { $0.lastPractice ?? .distantPast < $1.lastPractice ?? .distantPast })
            case .frequency:
                return items.sorted(by: { $0.relativeFrequency < $1.relativeFrequency })
            case .score:
                return items.sorted(by: { ItemScore($0) > ItemScore($1) })
        }
    }
    
    // Returns medium and high rank
    func scoreColors() -> (Double, Double) {
        var scores: [Double] = []
        for item in items {
            scores.append(ItemScore(item))
        }
        
        if scores.count == 0 {
            return (0.0, 0.0)
        } else if scores.count == 1 {
            return (scores[0], scores[0])
        } else {
            let mean = scores.reduce(0.0, +) / Double(scores.count)
            return ((3.0 * mean + scores.max()!) / 4.0,
                    (mean + 2.0 * scores.max()!) / 3.0)
        }
    }
    
    func itemColor(item: Item, mediumScore: Double, highScore: Double) -> Color {
        if ItemAge(item.lastPractice ?? .distantPast) == 0 {
            return .primary
        }
        
        let score = ItemScore(item)
        if score > highScore {
            return Color("HighScoreColor")
        } else if score > mediumScore {
            return Color("MediumScoreColor")
        } else {
            #if os(macOS)
            return Color(NSColor.textColor)
            #else
            return .primary
            #endif
        }
    }
}

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
    @Environment(\.managedObjectContext) var moc
    
    @FocusState private var categoryTitleInFocus: Bool
    
    var items: [Item] {
        return category.items?.allObjects as? [Item] ?? []
    }
    
    // sortedItems is State for animation purposes
    @State var sortedItems: [Item] = []
    
    init(category: Category) {
        self.category = category
        let name = category.name ?? ""
        self._title = State(initialValue: name == "New Category" ? "" : name)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                TextField("New Category", text: $title)
                    .multilineTextAlignment(.center)
                    .focused($categoryTitleInFocus)
                    .font(.title2)
                    .foregroundColor(Color("TextColor"))
                    .padding()
                
                HStack(alignment: .center) {
                    Button() {
                        state.selectedCategory = nil
                        state.selectedItem = nil
                    } label: {
                        Image(systemName: "arrowshape.turn.up.backward").font(Font.system(.title)).padding()
                    }
                    
                    Spacer()
                    
                    Menu {
                        Picker("Flavor", selection: $state.sortOrder) {
                            Label("Sort Alphabetically", systemImage: "textformat.abc").tag(SortOrder.alphabetical)
                            Label("Sort by Last Practiced", systemImage: "timer").tag(SortOrder.lastPracticed)
                            Label("Sort by Frequency", systemImage: "waveform").tag(SortOrder.frequency)
                            Label("Sort by Ranking", systemImage: "list.number").tag(SortOrder.score)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle").font(Font.system(.title))
                    }
                    .buttonStyle(BorderlessButtonStyle())  // Prevent multiple buttons from being clicked
                    .padding()
                }
            }.background(Color("HeaderColor"))
            
            if title == "" || sortedItems.isEmpty {
                Spacer()
                
                VStack(alignment: .leading) {
                    if title == "" {
                        Text("Set the name for this practice category by tapping on \"Category title\"")
                            .myText()
                            .fixedSize(horizontal: false, vertical: true)
                            .padding()
                    }
                    if sortedItems.isEmpty {
                        Text("Add your first practice item (examples: C Major Scale, Mary Had a Little Lamb, etc.) by clicking on the \"Add Practice Item\" button")
                            .myText()
                            .fixedSize(horizontal: false, vertical: true)
                            .padding()
                    }
                }
            }
            
            let (mediumScore, highScore) = scoreColors()
            List {
                ForEach(Array(sortedItems.enumerated()), id: \.1.id) { (index, item) in
                    let color: Color = itemColor(item: item, mediumScore: mediumScore, highScore: highScore)
                    itemRow(item, color: color)
                }
            }.listStyle(.plain)
            
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
        }.onAppear {
            if title == "" {
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
    
    func itemRow(_ item: Item, color: Color) -> some View {
        HStack(alignment: .center) {
            let practicedToday = ItemAge(item.lastPractice ?? .distantPast) == 0
            Button() {
                togglePracticed(item)
                try? moc.save()
                withAnimation(.easeIn) {
                    sortedItems = sortItems()
                }
                // Increment state counter. This catches an issue where the
                // view will not update if the sort order does not change.
                state.changedCounter += 1
            } label: {
                let sfName = practicedToday ? "checkmark.circle" : "circle"
                Image(systemName: sfName).font(Font.system(.title2))
            }.buttonStyle(BorderlessButtonStyle())  // Prevent multiple buttons from being clicked
            
            Button() {
                if state.selectedItem != nil && item.id == state.selectedItem!.id {
                    state.selectedItem = nil
                } else {
                    state.selectedItem = item
                }
            } label: {
                VStack(alignment: .leading) {
                    HStack {
                        Text(item.name ?? "Unknown")
                            .foregroundColor(color)
                            .myText()
                            .strikethrough(practicedToday)
                        Spacer()
                    }
                    if let notes = item.notes {
                        Text(notes)
                            .foregroundColor(.gray)
                            .myText()
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding([.top], 3)
                    }
                }
            }
            .buttonStyle(BorderlessButtonStyle())  // Prevent multiple buttons from being clicked
            .padding([.leading])
        }
        .padding([.top, .bottom], 12.0)
        .badge(itemBadge(item))
        .swipeActions(edge: .trailing) {
            Button() {
                togglePracticed(item)
                try? moc.save()
                state.changedCounter += 1
            } label: {
                Label("Practiced", systemImage: "checkmark")
            }.tint(.green)
            Button(role: .destructive) {
                moc.delete(item)
                try? moc.save()
                state.changedCounter += 1
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    func togglePracticed(_ item: Item) {
        let practicedToday = ItemAge(item.lastPractice ?? .distantPast) == 0
        if practicedToday {
            // Undo today's practice
            item.lastPractice = item.lastLastPractice
            item.lastLastPractice = nil
        } else {
            // Practice today
            item.lastLastPractice = item.lastPractice
            item.lastPractice = Date()
        }
    }
    
    func itemBadge(_ item: Item) -> String {
        switch state.sortOrder {
        case .alphabetical:
            return ""
        case .lastPracticed:
            if let lp = item.lastPractice {
                return String(ItemAge(lp))
            } else {
                return ""
            }
        case .frequency:
            let displayFrequency: Double = round(10.0 / item.relativeFrequency) / 10.0
            return String(format: "%.1fx", displayFrequency)
        case .score:
            return ""
        }
    }
}

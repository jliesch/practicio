//
//  ItemView.swift
//  Practicio
//
//  Created by Jesse Liesch on 8/5/22.
//

import SwiftUI

struct ItemView: View {
    let item: Item
    
    @EnvironmentObject var state: AppState
    @Environment(\.managedObjectContext) var moc
    @State var title: String
    @State var relativeFrequency: Double
    @State var notes: String
    @State var deleteItem = false
    @FocusState private var itemTitleInFocus: Bool
    
    init(item: Item) {
        self.item = item
        // Use empty name for editing if it's new
        let name = item.name ?? ""
        self._title = State(initialValue: name == "New Item" ? "" : name)
        self._relativeFrequency = State(initialValue: ItemView.frequencyToSlider(item.relativeFrequency))
        self._notes = State(initialValue: item.notes ?? "")
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                
                Spacer()

                TextField("Item title", text: $title).focused($itemTitleInFocus).font(.title2).foregroundColor(Color("TextColor"))

                if let lastPractice = item.lastPractice {
                    let days = ItemAge(lastPractice)
                    let isPlural = days != 1
                    Text(String(format: "Last practiced: %d day%@ ago", days, isPlural ? "s" : "")).myText().padding([.top, .bottom])
                } else {
                    Text("Last Practiced: Never").myText().padding([.top, .bottom])
                }
                
                let displayFrequency: Double = round(10.0 / ItemView.sliderToFrequency(relativeFrequency)) / 10.0
                let frequencyText: String = displayFrequency > 1.1 ? " (more often)" : displayFrequency < 0.9 ? " (less often)" : ""
                Text(String(format: "Practice frequency: %.1fx%@", displayFrequency, frequencyText)).myText()
                ZStack {
                    Slider(value: $relativeFrequency, in: 0.0...1.0)
                    HStack {
                        Rectangle().frame(width: 2.0, height: 12.0).foregroundColor(.blue)
                        Spacer()
                        Rectangle().frame(width: 2.0, height: 12.0).foregroundColor(.blue)
                        Spacer()
                        Rectangle().frame(width: 2.0, height: 12.0).foregroundColor(.blue)
                        Spacer()
                        Rectangle().frame(width: 2.0, height: 12.0).foregroundColor(.blue)
                        Spacer()
                        Rectangle().frame(width: 2.0, height: 12.0).foregroundColor(.blue)
                    }
                }
                
                Text("Notes").myText()
                TextEditor(text: $notes).frame(minHeight: geometry.size.height * 0.10, maxHeight: geometry.size.height * 0.20)
                
                Spacer()

                HStack {
                    Spacer()
                    VStack {
                        Button() {
                            deleteItem = true
                        } label: {
                            VStack {
                                Image(systemName: "trash").font(Font.system(.title))
                                Text("Delete Item").myText().padding(3)
                            }
                        }.buttonStyle(BorderlessButtonStyle())  // Prevent multiple buttons from being clicked
                            .padding()
                    }
                    Spacer()
                }
            }.ignoresSafeArea(.keyboard).padding().onAppear {
                // Delay selecting title a bit, otherwise it doesn't receive focus
                Task {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    if title == "" {
                        itemTitleInFocus = true
                    }
                }
            }.onChange(of: title) { newTitle in
                item.name = newTitle
                try? moc.save()
                state.changedCounter += 1
            }.onChange(of: relativeFrequency) { newFrequency in
                item.relativeFrequency = ItemView.sliderToFrequency(newFrequency)
                try? moc.save()
                state.changedCounter += 1
            }.onChange(of: notes) { newNotes in
                item.notes = newNotes
                try? moc.save()
            }.alert(isPresented: $deleteItem) {
                Alert(title: Text("Delete Item").myText(),
                      message: Text("Delete this item. Are you sure?").myText(),
                      primaryButton: .default(Text("Cancel")) { deleteItem = false },
                      secondaryButton: .destructive(Text("Delete")) {
                    moc.delete(item)
                    try? moc.save()
                    state.selectedItem = nil
                })
            }
        }
    }
    
    // Maps 0.1...10.0 to 0.0...1.0
    static func frequencyToSlider(_ frequency: Double) -> Double {
        // Apply an exponent to make 0.5 and 2x line up with the tick marks
        if frequency < 1.0 {
            return 1.0 - pow((frequency - Constants.minFrequency) / (Constants.avgFrequency - Constants.minFrequency), 1.0 / 1.07) * 0.5
        } else if frequency > 1.0 {
            return 0.5 - pow((frequency - Constants.avgFrequency) / (Constants.maxFrequency - Constants.avgFrequency), 1.0 / 3.5) * 0.5
        } else {
            return 0.5
        }
    }
    
    static func sliderToFrequency(_ frequency: Double) -> Double {
        let invFrequency = 1.0 - frequency
        if invFrequency < 0.5 {
            return Constants.minFrequency + pow(invFrequency / 0.5, 1.07) * (Constants.avgFrequency - Constants.minFrequency)
        } else if invFrequency > 0.5 {
            return Constants.avgFrequency + pow((invFrequency - 0.5) / 0.5, 3.5) * (Constants.maxFrequency - Constants.avgFrequency)
        } else {
            return Constants.avgFrequency
        }
    }

    var frequencyName: String {
        if relativeFrequency < 0.2 {
            return "Usually"
        } else if relativeFrequency < 0.4 {
            return "Routinely"
        } else if relativeFrequency < 0.6 {
            return "Ordinarily"
        }
        else if relativeFrequency < 0.8 {
            return "Occasionally"
        } else {
            return "Rarely"
        }
    }
}
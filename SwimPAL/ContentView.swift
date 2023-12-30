//
//  ContentView.swift
//  SwimPAL
//
//  Created by Benson Zhang on 11/16/23.
//

import SwiftUI

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MeetsView()
                .tabItem {
                    Image(systemName: "stopwatch")
                    Text("Meet")
                }

            TeamView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Team")
                }
        }
    }
}

struct Meet: Identifiable, Equatable, Codable {
    let id = UUID()
    var opponent: String
    var date: Date
}

class MeetStorage {
    private let meetsKey = "meets"
    
    func saveMeets(_ meets: [Meet]) {
        do {
            let data = try JSONEncoder().encode(meets)
            UserDefaults.standard.set(data, forKey: meetsKey)
        } catch {
            print("Error saving meets: \(error)")
        }
    }
    
    func loadMeets() -> [Meet] {
        guard let data = UserDefaults.standard.data(forKey: meetsKey) else { return [] }
        do {
            return try JSONDecoder().decode([Meet].self, from: data)
        } catch {
            print("Error loading meets: \(error)")
            return []
        }
    }
}


// Meets View
struct MeetsView: View {
    @State private var showingMeetForm = false
    @State private var meets = [Meet]() // Array to store meets
    private var teamMembers: [String] {
        UserDefaults.standard.object(forKey: "teamMembers") as? [String] ?? []
    }
    var body: some View {
        NavigationView {
            List {
                ForEach(meets) { meet in
                    NavigationLink(destination: LaneNumberInputView(meet: meet, teamMembers: teamMembers)) {
                        VStack(alignment: .leading) {
                            Text(meet.opponent)
                            Text("\(meet.date, formatter: itemFormatter)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }

                Button("Add New Meet") {
                    showingMeetForm = true
                }
            }
            .navigationTitle("Meets")
            .sheet(isPresented: $showingMeetForm) {
                MeetFormView { newMeet in
                    meets.append(newMeet)
                    MeetStorage().saveMeets(meets)
                }
            }
        }
    }
}


// Formatter for the meet date
private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .none
    return formatter
}()

// Form for Adding a New Meet
struct MeetFormView: View {
    @State private var opponentName: String = ""
    @State private var meetDate: Date = Date()
    @Environment(\.presentationMode) var presentationMode
    var onCreate: (Meet) -> Void // Closure to handle creation

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Opponent Name", text: $opponentName)
                    DatePicker("Date", selection: $meetDate, displayedComponents: .date)
                }

                Section {
                    Button("Create New Meet") {
                        let newMeet = Meet(opponent: opponentName, date: meetDate)
                        onCreate(newMeet)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("New Meet")
        }
    }
}

struct LaneNumberInputView: View {
    var meet: Meet
    var teamMembers: [String]
    @State private var selectedLanes: [Int] = []
    @State private var showingEventView = false

    var body: some View {
        VStack {
            Text("Your Team Lanes")
            LaneSelectionView(selectedLanes: $selectedLanes)
            
            Text("\(meet.opponent)'s Team Lanes")
            OpponentLaneView(selectedLanes: $selectedLanes)

            Button("Next") {
                showingEventView = true
            }
            .sheet(isPresented: $showingEventView) {
                // Pass teamMembers to EventDisplayView
                EventDisplayView(meet: meet, selectedLanes: selectedLanes)
            }
        }
    }
}


struct LaneSelectionView: View {
    @Binding var selectedLanes: [Int]

    var body: some View {
        HStack {
            ForEach(1...4, id: \.self) { lane in
                LaneButton(lane: lane, selectedLanes: $selectedLanes)
            }
        }
    }
}

struct LaneButton: View {
    var lane: Int
    @Binding var selectedLanes: [Int]

    var body: some View {
        Button(action: {
            if selectedLanes.contains(lane) {
                selectedLanes.removeAll(where: { $0 == lane })
            } else {
                selectedLanes.append(lane)
            }
        }) {
            Text("\(lane)")
                .frame(width: 40, height: 40)
                .foregroundColor(selectedLanes.contains(lane) ? .white : .black)
                .background(selectedLanes.contains(lane) ? Color.blue : Color.gray)
                .cornerRadius(8)
        }
    }
}

struct OpponentLaneView: View {
    @Binding var selectedLanes: [Int]

    var body: some View {
        HStack {
            ForEach(1...4, id: \.self) { lane in
                Text("\(lane)")
                    .frame(width: 40, height: 40)
                    .background(selectedLanes.contains(lane) ? Color.gray : Color.blue)
                    .cornerRadius(8)
            }
        }
    }
}


struct LaneNumberSection: View {
    let title: String
    @Binding var laneNumbers: [String]

    var body: some View {
        Text(title)
        ForEach($laneNumbers.indices, id: \.self) { index in
            HStack {
                TextField("Lane Number", text: $laneNumbers[index])
                Button("Remove") {
                    if laneNumbers.count > 1 {
                        laneNumbers.remove(at: index)
                    }
                }
            }
        }
        Button("Add Lane Number") {
            laneNumbers.append("")
        }
    }
}

struct EventRow: Identifiable {
    let id = UUID()
    var lane: Int
    var swimmer: String = ""
    var time: String = ""
    var place: String = ""
}

//events: ["4x50 Medley Relay", "200 Freestyle", "200 Individual Medley", "50 Freestyle", "Diving", "100 Butterfly", "100 Freestyle", "500 Freestyle", "4x50 Freestyle Relay", "100 Backstroke", "100 Breaststroke", "4x100 Freestyle Relay"]
struct EventDisplayView: View {
    var meet: Meet
    var selectedLanes: [Int]
    @State private var rows: [EventRow] = (1...4).map { EventRow(lane: $0) }
    let events = ["4x50 Medley Relay", "200 Freestyle", "200 Individual Medley", "50 Freestyle", "Diving", "100 Butterfly", "100 Freestyle", "500 Freestyle", "4x50 Freestyle Relay", "100 Backstroke", "100 Breaststroke", "4x100 Freestyle Relay"]

    var body: some View {
        List {
            ForEach(events, id: \.self) { event in
                VStack(alignment: .leading) {
                    Text(event).font(.headline)
                    EventTable(selectedLanes: selectedLanes, rows: $rows)
                }
            }
        }
        .navigationTitle("\(meet.opponent) - \(meet.date, formatter: itemFormatter)")
    }
}


struct EventTable: View {
    var selectedLanes: [Int]
    @Binding var rows: [EventRow]

    var body: some View {
        ForEach($rows, id: \.lane) { $row in
            HStack {
                Text("\(row.lane)")

                TextField("Swimmer", text: $row.swimmer)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                TextField("Time", text: $row.time)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                TextField("Place", text: $row.place)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
            }
        }
    }
}

struct SwimmerPickerView: View {
    var teamMembers: [String]
    @Binding var selectedSwimmer: String

    var body: some View {
        NavigationView {
            List {
                ForEach(teamMembers, id: \.self) { member in
                    Button(member) {
                        selectedSwimmer = member
                    }
                }
            }
            .navigationBarTitle("Select Swimmer", displayMode: .inline)
        }
    }
}


struct RoundedTextField: View {
    var placeholder: String

    var body: some View {
        TextField(placeholder, text: .constant(""))
            .padding(10)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .frame(height: 40)
    }
}



struct TeamView: View {
    @State private var teamName: String = UserDefaults.standard.string(forKey: "teamName") ?? ""
    @State private var newMemberName: String = ""
    @State private var teamMembers: [String] = UserDefaults.standard.object(forKey: "teamMembers") as? [String] ?? []

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Team Information")) {
                        TextField("Team Name", text: $teamName, onCommit: saveTeamData)
                    }

                    Section(header: Text("Add Member")) {
                        TextField("Member Name", text: $newMemberName)
                        Button("Add") {
                            addMember()
                            saveTeamData()
                        }
                    }
                }

                List(teamMembers, id: \.self) { member in
                    Text(member)
                }
            }
            .navigationTitle(teamName.isEmpty ? "Team" : teamName)
        }
    }

    private func addMember() {
        if !newMemberName.isEmpty {
            teamMembers.append(newMemberName)
            newMemberName = ""
        }
    }

    private func saveTeamData() {
        UserDefaults.standard.set(teamName, forKey: "teamName")
        UserDefaults.standard.set(teamMembers, forKey: "teamMembers")
    }
}

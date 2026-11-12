import Foundation
import Testing
@testable import RoomsCore

private let f = FractionalFrame(x: 0, y: 0, w: 1, h: 1)
private func slot(_ app: String, on display: String) -> WindowSlot {
    WindowSlot(bundleID: app, title: app, display: display, frame: f)
}
/// Call at the desk: Dell + laptop + LG.
private let desk = Room(name: "Call", apps: [AppRef("zoom"), AppRef("slack")],
                        windows: [slot("zoom", on: "DELL"), slot("slack", on: "DELL"), slot("messages", on: "LAPTOP"), slot("iterm", on: "LG")])
private let deskDisplays = ["DELL", "LAPTOP", "LG"]

// MARK: Storage

@Test func aLegacyRoomLoadsAsOneSetupOnItsWindowsDisplays() throws {
    let json = #"{"version":1,"rooms":[{"name":"Call","windows":[{"bundleID":"zoom","title":"Zoom","display":"DELL","frame":{"x":0,"y":0,"w":1,"h":1}},{"bundleID":"iterm","title":"iTerm","display":"LG","frame":{"x":0,"y":0,"w":1,"h":1}}],"layoutByDisplay":{"DELL":"focus"}}]}"#
    let room = try JSONDecoder().decode(RoomsFile.self, from: Data(json.utf8)).rooms[0]
    #expect(room.setupDisplays == ["DELL", "LG"])
    #expect(room.windows.map(\.bundleID) == ["zoom", "iterm"])
    #expect(room.layoutByDisplay == ["DELL": .focus])
    #expect(room.otherSetups.isEmpty)
}

@Test func roomsWithSeveralSetupsRoundTrip() throws {
    var room = desk
    room.setupDisplays = deskDisplays
    room.otherSetups = [Setup(displays: ["LAPTOP"], windows: [slot("zoom", on: "LAPTOP")], apps: [AppRef("zoom")], layoutByDisplay: ["LAPTOP": .stack])]
    let data = try JSONEncoder().encode(RoomsFile(rooms: [room]))
    #expect(try JSONDecoder().decode(RoomsFile.self, from: data).rooms == [room])
    let text = String(decoding: data, as: UTF8.self)
    #expect(text.contains("\"setups\""))
    #expect(!text.contains("\"windows\":[],"))   // the active setup is written inside `setups`, not twice
}

// MARK: Choosing a setup for the connected displays

private var twoSetups: Room {
    var room = desk
    room.setupDisplays = deskDisplays
    room.otherSetups = [Setup(displays: ["LAPTOP"], windows: [slot("zoom", on: "LAPTOP")], apps: [AppRef("zoom")], layoutByDisplay: [:])]
    return room
}

@Test func theSetupForExactlyTheseDisplaysWins() {
    let room = twoSetups.resolved(for: ["LAPTOP"])
    #expect(room.setupDisplays == ["LAPTOP"])
    #expect(room.windows.map(\.bundleID) == ["zoom"])
    #expect(room.otherSetups.map(\.displays) == [deskDisplays])
}

@Test func displayOrderDoesNotMatter() {
    #expect(twoSetups.resolved(for: ["LG", "DELL", "LAPTOP"]).setupDisplays == deskDisplays)
}

@Test func withNoExactMatchTheSetupSharingMostDisplaysWins() {
    // Laptop + LG: the desk setup shares two displays, the laptop setup one.
    #expect(twoSetups.resolved(for: ["LAPTOP", "LG"]).setupDisplays == deskDisplays)
}

@Test func aTieGoesToTheBiggerSetup() {
    // A display neither setup knows: both share nothing; the desk setup is bigger.
    #expect(twoSetups.resolved(for: ["OFFICE"]).setupDisplays == deskDisplays)
}

@Test func aRoomWithOneSetupIsUnchangedByResolving() {
    #expect(desk.resolved(for: ["LAPTOP"]) == desk)
}

// MARK: Saving on a new set of displays

@Test func savingOnOtherDisplaysStartsAFreshSetupAndKeepsTheOldOne() {
    var room = desk
    room.setupDisplays = deskDisplays
    room.beginSetup(for: ["LAPTOP"])
    #expect(room.setupDisplays == ["LAPTOP"])
    #expect(room.windows.isEmpty && room.apps.isEmpty && room.layoutByDisplay.isEmpty)
    #expect(room.otherSetups.map(\.displays) == [deskDisplays])
    #expect(room.otherSetups[0].windows == desk.windows)
}

@Test func savingOnTheSameDisplaysKeepsTheSetup() {
    var room = desk
    room.setupDisplays = deskDisplays
    room.beginSetup(for: ["LG", "LAPTOP", "DELL"])
    #expect(room.windows == desk.windows)
    #expect(room.otherSetups.isEmpty)
}

@Test func aNewSetupReplacesAnOldOneForTheSameDisplays() {
    var room = twoSetups   // active: desk; other: laptop
    room.beginSetup(for: ["LAPTOP"])
    #expect(room.setupDisplays == ["LAPTOP"])
    #expect(room.windows.isEmpty)
    #expect(room.otherSetups.map(\.displays) == [deskDisplays])
}

@Test func anEmptySetupIsNotKeptAside() {
    var room = Room(name: "New")
    room.beginSetup(for: ["LAPTOP"])
    #expect(room.setupDisplays == ["LAPTOP"])
    #expect(room.otherSetups.isEmpty)
}

@Test func duplicateCopiesEverySetup() {
    let copy = twoSetups.duplicated(among: [twoSetups])
    #expect(copy.otherSetups == twoSetups.otherSetups)
    #expect(copy.setupDisplays == deskDisplays)
}

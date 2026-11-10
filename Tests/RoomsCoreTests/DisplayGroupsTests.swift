import Testing
@testable import RoomsCore

// A room's windows and the display each was saved on. `nil` is a window with no
// display recorded (rooms.json from before displays were kept).

@Test func roomSpanningDisplaysKeepsEachWindowOnItsDisplay() {
    let groups = DisplayGroups.split(displays: ["A", "B", "A"], connected: ["A", "B", "C"], fallback: "C")
    #expect(groups == [DisplayGroups.Group(display: "A", members: [0, 2]), DisplayGroups.Group(display: "B", members: [1])])
}

@Test func roomOnOneDisplayComesToTheFallbackDisplay() {
    // A single-display room follows you (the display under the mouse), as before.
    let groups = DisplayGroups.split(displays: ["A", "A"], connected: ["A", "B"], fallback: "B")
    #expect(groups == [DisplayGroups.Group(display: "B", members: [0, 1])])
}

@Test func windowsOfADisconnectedDisplayJoinTheFallbackDisplay() {
    let groups = DisplayGroups.split(displays: ["A", "B", "X"], connected: ["A", "B"], fallback: "B")
    #expect(groups == [DisplayGroups.Group(display: "A", members: [0]), DisplayGroups.Group(display: "B", members: [1, 2])])
}

@Test func windowsWithNoDisplayJoinTheFallbackDisplay() {
    let groups = DisplayGroups.split(displays: ["A", nil, "B"], connected: ["A", "B", "C"], fallback: "C")
    #expect(groups == [DisplayGroups.Group(display: "A", members: [0]),
                       DisplayGroups.Group(display: "B", members: [2]),
                       DisplayGroups.Group(display: "C", members: [1])])
}

@Test func groupsFollowTheConnectedDisplayOrder() {
    let groups = DisplayGroups.split(displays: ["C", "A"], connected: ["A", "B", "C"], fallback: "B")
    #expect(groups.map(\.display) == ["A", "C"])
}

@Test func spanningRoomWhoseDisplaysAreAllGoneComesToTheFallbackDisplay() {
    let groups = DisplayGroups.split(displays: ["X", "Y"], connected: ["A"], fallback: "A")
    #expect(groups == [DisplayGroups.Group(display: "A", members: [0, 1])])
}

@Test func noWindowsMakesNoGroups() {
    #expect(DisplayGroups.split(displays: [], connected: ["A"], fallback: "A").isEmpty)
}

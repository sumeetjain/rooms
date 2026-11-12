import Testing
@testable import RoomsCore

private let design = Room(id: "design", name: "Design", aliases: ["ds"], kind: "Work",
                          apps: [AppRef("com.figma.Desktop", name: "Figma")],
                          windows: [WindowSlot(bundleID: "com.figma.Desktop", title: "Deck", frame: FractionalFrame(x: 0, y: 0, w: 1, h: 1))],
                          layout: .focus)

@Test func duplicateKeepsTheWindowsAndLayout() {
    let copy = design.duplicated(among: [design])
    #expect(copy.windows == design.windows)
    #expect(copy.apps == design.apps)
    #expect(copy.layout == .focus)
    #expect(copy.kind == "Work")
}

@Test func duplicateIsNamedCopyWithItsOwnID() {
    let copy = design.duplicated(among: [design])
    #expect(copy.name == "Design Copy")
    #expect(copy.id == "design-copy")
}

@Test func duplicateNamesCountUpWhenACopyExists() {
    let first = design.duplicated(among: [design])
    let second = design.duplicated(among: [design, first])
    #expect(second.name == "Design Copy 2")
    #expect(second.id == "design-copy-2")
}

@Test func duplicateLeavesAliasesAndShortcutBehind() {
    // Both would make the palette and ⌃⌥n ambiguous between the two rooms.
    var keyed = design
    keyed.shortcut = 3
    let copy = keyed.duplicated(among: [keyed])
    #expect(copy.aliases.isEmpty)
    #expect(copy.shortcut == nil)
}

@Test func duplicateIDAvoidsARoomWhoseIDClashesUnderADifferentName() {
    var other = design
    other.id = "design-copy"
    other.name = "Something else"
    // Name and id move together, so what you see always matches what's in rooms.json.
    let copy = design.duplicated(among: [design, other])
    #expect(copy.name == "Design Copy 2")
    #expect(copy.id == "design-copy-2")
}

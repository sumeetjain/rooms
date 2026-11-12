import CoreGraphics
import Testing
@testable import RoomsCore

// Window numbers come from the window server (CGWindowList), which lists each
// window's owner and bounds but not its Accessibility element. An AX window is
// matched to its number by owner and frame.

private func cg(_ id: UInt32, pid: Int32, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, layer: Int = 0) -> WindowNumbers.Entry {
    WindowNumbers.Entry(id: id, pid: pid, bounds: CGRect(x: x, y: y, width: w, height: h), layer: layer)
}

@Test func matchesByOwnerAndFrame() {
    let numbers = WindowNumbers(entries: [cg(10, pid: 1, 0, 0, 800, 600), cg(11, pid: 2, 0, 0, 800, 600)])
    #expect(numbers.id(forWindowOf: 2, at: CGRect(x: 0, y: 0, width: 800, height: 600)) == 11)
}

@Test func aFrameOffByAPointStillMatches() {
    // Accessibility and the window server round differently now and then.
    let numbers = WindowNumbers(entries: [cg(10, pid: 1, 100, 50, 800, 600)])
    #expect(numbers.id(forWindowOf: 1, at: CGRect(x: 101, y: 50, width: 799, height: 601)) == 10)
}

@Test func onlyOrdinaryWindowsCount() {
    // Menus, toasts and floating panels live on other layers.
    let numbers = WindowNumbers(entries: [cg(10, pid: 1, 0, 0, 800, 600, layer: 25), cg(11, pid: 1, 0, 0, 800, 600)])
    #expect(numbers.id(forWindowOf: 1, at: CGRect(x: 0, y: 0, width: 800, height: 600)) == 11)
}

@Test func twoWindowsOnTheSameFrameAreHandedOutOnce() {
    let numbers = WindowNumbers(entries: [cg(10, pid: 1, 0, 0, 800, 600), cg(11, pid: 1, 0, 0, 800, 600)])
    let frame = CGRect(x: 0, y: 0, width: 800, height: 600)
    let first = numbers.id(forWindowOf: 1, at: frame)
    let second = numbers.id(forWindowOf: 1, at: frame)
    #expect(first != nil && second != nil && first != second)
    #expect(numbers.id(forWindowOf: 1, at: frame) == nil)
}

@Test func noWindowOfThatOwnerOrFrameMeansNoNumber() {
    let numbers = WindowNumbers(entries: [cg(10, pid: 1, 0, 0, 800, 600)])
    #expect(numbers.id(forWindowOf: 1, at: CGRect(x: 0, y: 0, width: 400, height: 300)) == nil)
    #expect(numbers.id(forWindowOf: 9, at: CGRect(x: 0, y: 0, width: 800, height: 600)) == nil)
}

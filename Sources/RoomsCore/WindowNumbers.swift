import CoreGraphics

/// Window numbers (CGWindowID) for Accessibility windows, from the window server's
/// list of windows: it names each window's owner and bounds but not its Accessibility
/// element, so a window is matched by owner and frame. Two windows of one app on the
/// same frame are told apart only by order: each number is handed out once.
public final class WindowNumbers {
    public struct Entry: Sendable {
        public let id: CGWindowID
        public let pid: Int32
        public let bounds: CGRect
        /// 0 for ordinary windows; menus, toasts and floating panels sit higher.
        public let layer: Int

        public init(id: CGWindowID, pid: Int32, bounds: CGRect, layer: Int) {
            self.id = id
            self.pid = pid
            self.bounds = bounds
            self.layer = layer
        }
    }

    private let entries: [Entry]
    private var used: Set<CGWindowID> = []

    /// `entries` front to back, as the window server lists them.
    public init(entries: [Entry]) {
        self.entries = entries.filter { $0.layer == 0 }
    }

    /// The number of `pid`'s window at `frame` (within a couple of points), or nil.
    public func id(forWindowOf pid: Int32, at frame: CGRect) -> CGWindowID? {
        func close(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) <= 2 }
        let match = entries.first { e in
            e.pid == pid && !used.contains(e.id)
                && close(e.bounds.minX, frame.minX) && close(e.bounds.minY, frame.minY)
                && close(e.bounds.width, frame.width) && close(e.bounds.height, frame.height)
        }
        if let match { used.insert(match.id) }
        return match?.id
    }
}

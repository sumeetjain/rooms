import Foundation

/// Which display each of a room's windows goes to. A room saved across several
/// displays spreads back over them; a room saved on one display follows you to the
/// display you're on (`fallback`), as it always has.
public enum DisplayGroups {
    public struct Group: Equatable, Sendable {
        /// A connected display's UUID.
        public let display: String
        /// Indices into `displays`, in their original order.
        public let members: [Int]

        public init(display: String, members: [Int]) {
            self.display = display
            self.members = members
        }
    }

    /// `displays[i]` is the display item `i` was saved on (nil when none was recorded).
    /// Items keep their display only when the items span more than one *connected*
    /// display; everything else (a single-display room, a display that's gone, no
    /// display) goes to `fallback`. Groups come in `connected` order.
    public static func split(displays: [String?], connected: [String], fallback: String) -> [Group] {
        guard !displays.isEmpty else { return [] }
        let known = Set(connected)
        let kept = displays.map { $0.flatMap { known.contains($0) ? $0 : nil } }
        let spans = Set(kept.compactMap { $0 }).count > 1
        var members: [String: [Int]] = [:]
        for (i, display) in kept.enumerated() {
            let target = spans ? (display ?? fallback) : fallback
            members[target, default: []].append(i)
        }
        let order = connected.contains(fallback) ? connected : connected + [fallback]
        return order.compactMap { uuid in members[uuid].map { Group(display: uuid, members: $0) } }
    }
}

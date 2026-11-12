import CoreGraphics
import Foundation
import RoomsCore

extension WindowNumbers {
    /// Every window the window server knows right now, including those of hidden
    /// apps and minimized ones. Needs no permission (names are not read).
    static func current() -> WindowNumbers {
        let list = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        return WindowNumbers(entries: list.compactMap { info in
            guard let id = info[kCGWindowNumber as String] as? CGWindowID,
                  let pid = info[kCGWindowOwnerPID as String] as? Int32,
                  let dict = info[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: dict) else { return nil }
            return Entry(id: id, pid: pid, bounds: bounds, layer: info[kCGWindowLayer as String] as? Int ?? 0)
        })
    }
}

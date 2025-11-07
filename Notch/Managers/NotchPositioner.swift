//
//  NotchPositioner.swift
//  Notch
//
//  Created by Nikita Stogniy on 7/11/25.
//

import AppKit

class NotchPositioner {
    /// Position window at the notch area (top center of screen)
    static func positionAtNotch(window: NSWindow) {
        guard let screen = NSScreen.main else {
            print("❌ No main screen found!")
            return
        }

        let screenFrame = screen.frame
        let windowFrame = window.frame

        print("📐 Screen frame: \(screenFrame)")
        print("📐 Window frame: \(windowFrame)")

        // Calculate center position horizontally
        let xPosition = (screenFrame.width - windowFrame.width) / 2 + screenFrame.origin.x

        // Position just below the menu bar
        // Menu bar height is typically 24-25pt
        let menuBarHeight: CGFloat = 25
        var yPosition = screenFrame.maxY - menuBarHeight - windowFrame.height

        print("📍 Positioning below menu bar at y=\(yPosition)")

        let origin = NSPoint(x: xPosition, y: yPosition)
        print("📍 Final position: \(origin)")
        window.setFrameOrigin(origin)
        print("✅ Window positioned!")
    }

    /// Get notch dimensions if available
    static func getNotchInfo() -> (hasNotch: Bool, height: CGFloat) {
        guard let screen = NSScreen.main else {
            return (false, 0)
        }

        if #available(macOS 12.0, *) {
            let topInset = screen.safeAreaInsets.top
            return (topInset > 0, topInset)
        }

        return (false, 0)
    }

    /// Calculate ideal window width based on screen size
    static func calculateIdealWidth(for state: NotchState) -> CGFloat {
        guard let screen = NSScreen.main else {
            return state == .collapsed ? 218 : 680
        }

        let screenWidth = screen.frame.width

        switch state {
        case .collapsed:
            return min(218, screenWidth * 0.2)
        case .expanded:
            return min(680, screenWidth * 0.5)
        }
    }
}

// MARK: - Notch State Extension
extension NotchState {
    var windowSize: NSSize {
        switch self {
        case .collapsed:
            return NSSize(width: 200, height: 32)  // Fit into physical notch (~37pt)
        case .expanded:
            return NSSize(width: 680, height: 200)
        }
    }
}

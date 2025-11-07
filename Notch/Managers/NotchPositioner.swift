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

        // Position at the very top of screen (in notch area)
        let notchInfo = getNotchInfo()
        let yPosition = screenFrame.maxY - windowFrame.height

        if notchInfo.hasNotch {
            print("📍 Positioning in notch area (notch height: \(notchInfo.height)pt) at y=\(yPosition)")
        } else {
            print("📍 Positioning at top of screen (no notch) at y=\(yPosition)")
        }

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
            return state == .collapsed ? 300 : 680
        }

        let screenWidth = screen.frame.width

        switch state {
        case .collapsed:
            return min(300, screenWidth * 0.2)
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
            return NSSize(width: 310, height: 40)  // Extended width for side buttons
        case .expanded:
            return NSSize(width: 680, height: 300)
        }
    }
}

//
//  NotchPositioner.swift
//  Notch
//
//  Created by Nikita Stogniy on 7/11/25.
//

import AppKit

class NotchPositioner {
    /// Position window at the notch area (top center of screen)
    /// Window is fixed at 680x1200, content at top expands downward
    static func positionAtNotch(window: NSWindow) {
        guard let screen = NSScreen.main else {
            return
        }

        let screenFrame = screen.frame

        // Fixed window size
        let fixedWidth: CGFloat = 680
        let fixedHeight: CGFloat = 1200

        // Set fixed size first
        window.setContentSize(NSSize(width: fixedWidth, height: fixedHeight))

        // Calculate center position horizontally
        let xPosition = (screenFrame.width - fixedWidth) / 2 + screenFrame.origin.x

        // Position window so top is at screen top (in notch area)
        // Content expands downward from the notch
        let yPosition = screenFrame.maxY - fixedHeight

        let origin = NSPoint(x: xPosition, y: yPosition)
        window.setFrameOrigin(origin)
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

    /// Fixed window size (always the same)
    static let fixedWindowSize = NSSize(width: 680, height: 1200)
}

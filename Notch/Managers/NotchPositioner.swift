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
            print("❌ No main screen found!")
            return
        }

        let screenFrame = screen.frame

        // Fixed window size
        let fixedWidth: CGFloat = 680
        let fixedHeight: CGFloat = 1200

        // Set fixed size first
        window.setContentSize(NSSize(width: fixedWidth, height: fixedHeight))
        let windowFrame = window.frame

        print("📐 Screen frame: \(screenFrame)")
        print("📐 Window frame (fixed): \(windowFrame)")

        // Calculate center position horizontally
        let xPosition = (screenFrame.width - fixedWidth) / 2 + screenFrame.origin.x

        // Position window so top is at screen top (in notch area)
        // Content expands downward from the notch
        let yPosition = screenFrame.maxY - fixedHeight

        let notchInfo = getNotchInfo()
        if notchInfo.hasNotch {
            print("📍 Positioning in notch area (notch height: \(notchInfo.height)pt) at y=\(yPosition)")
        } else {
            print("📍 Positioning at top of screen at y=\(yPosition)")
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

    /// Fixed window size (always the same)
    static let fixedWindowSize = NSSize(width: 680, height: 1200)
}

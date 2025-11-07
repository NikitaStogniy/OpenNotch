//
//  FloatingWindowManager.swift
//  Notch
//
//  Created by Nikita Stogniy on 7/11/25.
//

import AppKit
import SwiftUI
import SwiftData
import Combine

class FloatingWindowManager: ObservableObject {
    static let shared = FloatingWindowManager()

    var panel: NSPanel?
    @Published var isVisible = true

    private var modelContainer: ModelContainer?

    private init() {}

    func createFloatingPanel(modelContainer: ModelContainer) {
        print("📦 Creating floating panel...")
        self.modelContainer = modelContainer

        // Create panel with initial collapsed size
        // Using .borderless and .fullSizeContentView for floating appearance
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 218, height: 40),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        print("🎨 Configuring panel appearance...")

        // Transparency and visual settings
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false

        // Floating panel - lower level so menu bar icons can be above it
        panel.level = .floating
        panel.collectionBehavior = [
            .canJoinAllSpaces,          // Visible on all spaces/desktops
            .stationary,                 // Doesn't move when switching spaces
            .fullScreenAuxiliary         // Visible in fullscreen mode
        ]

        // Interaction settings
        panel.isMovableByWindowBackground = false
        panel.acceptsMouseMovedEvents = true
        panel.ignoresMouseEvents = false

        // Hide window controls
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        // Don't hide when clicking elsewhere
        panel.hidesOnDeactivate = false

        print("🎭 Creating NotchView...")

        // Create NotchView with model container
        let notchView = NotchView()
            .modelContainer(modelContainer)

        // Set SwiftUI content
        let hostingView = NSHostingView(rootView: notchView)
        hostingView.wantsLayer = true
        hostingView.layer?.masksToBounds = false
        panel.contentView = hostingView

        self.panel = panel

        print("📍 Positioning at notch...")
        // Position at notch
        NotchPositioner.positionAtNotch(window: panel)

        print("✅ Panel frame: \(panel.frame)")
        print("✅ Panel level: \(panel.level.rawValue)")

        // Observe screen changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screenParametersChanged() {
        guard let panel = panel else { return }
        NotchPositioner.positionAtNotch(window: panel)
    }

    func show() {
        print("👁️ Showing panel...")
        panel?.makeKeyAndOrderFront(nil)
        panel?.orderFrontRegardless()
        isVisible = true
        print("✅ Panel should be visible now at: \(panel?.frame ?? .zero)")
    }

    func hide() {
        print("🙈 Hiding panel...")
        panel?.orderOut(nil)
        isVisible = false
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func updateSize(width: CGFloat, height: CGFloat, animated: Bool = true, resetPosition: Bool = false) {
        guard let panel = panel, let screen = NSScreen.main else { return }

        var newFrame = panel.frame
        let widthDiff = width - newFrame.width
        let heightDiff = height - newFrame.height

        newFrame.size.width = width
        newFrame.size.height = height

        // Center horizontally
        let screenFrame = screen.frame
        let centerX = (screenFrame.width - width) / 2 + screenFrame.origin.x
        newFrame.origin.x = centerX

        // Keep top edge fixed, grow downward
        newFrame.origin.y -= heightDiff

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.4
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(newFrame, display: true)
            }
        } else {
            panel.setFrame(newFrame, display: true)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// Environment key for FloatingWindowManager
private struct FloatingWindowManagerKey: EnvironmentKey {
    static let defaultValue: FloatingWindowManager? = nil
}

extension EnvironmentValues {
    var floatingWindowManager: FloatingWindowManager? {
        get { self[FloatingWindowManagerKey.self] }
        set { self[FloatingWindowManagerKey.self] = newValue }
    }
}

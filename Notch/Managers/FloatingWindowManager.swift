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

// Custom NSPanel subclass that can become key window for keyboard events
// and tracks mouse position to allow clicks through in non-interactive areas
class KeyablePanel: NSPanel {
    var notchContainerFrame: CGRect?

    override var canBecomeKey: Bool {
        return true
    }

    override var acceptsMouseMovedEvents: Bool {
        get { return true }
        set { }
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)

        // Get mouse location in window coordinates
        let mouseLocation = event.locationInWindow

        // Check if mouse is within notchContainer
        if let containerFrame = notchContainerFrame {
            let isInside = containerFrame.contains(mouseLocation)
            ignoresMouseEvents = !isInside
        } else {
            // No container frame set, accept all events by default
            ignoresMouseEvents = false
        }
    }
}

class FloatingWindowManager: ObservableObject {
    static let shared = FloatingWindowManager()

    var panel: NSPanel?
    @Published var isVisible = true

    private var modelContainer: ModelContainer?

    private init() {}

    func createFloatingPanel(modelContainer: ModelContainer) {
        print("📦 Creating floating panel...")
        self.modelContainer = modelContainer

        // Create panel with fixed size (680x1200)
        // Using .borderless and .fullSizeContentView for floating appearance
        // Using custom KeyablePanel to enable keyboard events
        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 1200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        print("🎨 Configuring panel appearance...")

        // Transparency and visual settings
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false

        // Set window level above menu bar to appear in notch area
        // Using mainMenu level + 2 to ensure it's above menu bar
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
        panel.collectionBehavior = [
            .canJoinAllSpaces,          // Visible on all spaces/desktops
            .stationary,                 // Doesn't move when switching spaces
            .fullScreenAuxiliary,        // Visible in fullscreen mode
            .ignoresCycle                // Don't participate in window cycling
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

    func makeKey() {
        panel?.makeKey()
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

    // DEPRECATED: Window size is now fixed at 680x720
    // Content animations are handled by SwiftUI
    func updateSize(width: CGFloat, height: CGFloat, animated: Bool = true, resetPosition: Bool = false) {
        // No-op: size is fixed, animations are in SwiftUI
        // This method is kept for backwards compatibility but does nothing
    }

    // Update window position based on visible content height
    func updatePosition(visibleHeight: CGFloat, animated: Bool = true) {
        guard let panel = panel, let screen = NSScreen.main else { return }

        let screenFrame = screen.frame
        let fixedWidth: CGFloat = 680
        let fixedHeight: CGFloat = 1200

        // Calculate center position horizontally
        let xPosition = (screenFrame.width - fixedWidth) / 2 + screenFrame.origin.x

        // Position window so top is at screen top (in notch)
        // Content expands downward from the notch
        let yPosition = screenFrame.maxY - fixedHeight

        let newOrigin = NSPoint(x: xPosition, y: yPosition)

        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.4
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0)
                panel.animator().setFrameOrigin(newOrigin)
            })
        } else {
            panel.setFrameOrigin(newOrigin)
        }
    }

    // Update the frame of notchContainer for mouse event handling
    func setNotchContainerFrame(_ frame: CGRect) {
        guard let panel = panel as? KeyablePanel else { return }
        panel.notchContainerFrame = frame
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

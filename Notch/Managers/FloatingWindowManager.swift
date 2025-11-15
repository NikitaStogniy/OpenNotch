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

// MARK: - Hit Testing Manager
class HitTestManager {
    var collapsedZoneFrame: CGRect?
    var expandedZoneFrame: CGRect?
    var currentState: NotchState = .collapsed
    let expansionAmount: CGFloat = 15  // Expansion for easier interaction in expanded state

    func setContainerFrame(_ frame: CGRect, notchState: NotchState) {
        // Ignore invalid frames (zero or negative dimensions)
        guard frame.width > 0 && frame.height > 0 else {
            return
        }

        collapsedZoneFrame = frame
        expandedZoneFrame = frame
        currentState = notchState
    }

    func getCurrentFrame() -> CGRect? {
        switch currentState {
        case .collapsed:
            // In collapsed state, use exact frame (no expansion to avoid blocking other windows)
            return collapsedZoneFrame
        case .expanded:
            // In expanded state, add expansion for easier interaction
            guard let frame = expandedZoneFrame else { return nil }
            return frame.insetBy(dx: -expansionAmount, dy: -expansionAmount)
        }
    }

    func isInZone(_ location: CGPoint) -> Bool {
        guard let frame = getCurrentFrame() else {
            return true // Accept all if no frame set
        }
        return frame.contains(location)
    }
}

// Custom content view with precise hit testing
class HitTestContentView: NSView {
    weak var hitTestManager: HitTestManager?

    override func hitTest(_ point: NSPoint) -> NSView? {
        // If no hit test manager or no frame set yet, use default behavior
        guard let manager = hitTestManager,
              manager.collapsedZoneFrame != nil else {
            return super.hitTest(point)
        }

        // Check if point is in active zone
        if !manager.isInZone(point) {
            // Point outside active zone - pass through (click-through)
            return nil
        }

        // Point inside active zone - use default NSView hit testing
        // This properly handles scroll events and all SwiftUI interactions
        return super.hitTest(point)
    }
}

// Custom NSPanel subclass that can become key window for keyboard events
// and tracks mouse position to allow clicks through in non-interactive areas
class KeyablePanel: NSPanel, NSDraggingDestination {
    private let hitTestManager = HitTestManager()
    private var isCurrentlyDragging = false
    private var trackingArea: NSTrackingArea?
    private var customContentView: HitTestContentView?

    // Update container frame (called from FloatingWindowManager)
    func setNotchContainerFrame(_ frame: CGRect, notchState: NotchState) {
        hitTestManager.setContainerFrame(frame, notchState: notchState)
        updateTrackingArea()
    }

    // Update tracking area when notch frame changes
    private func updateTrackingArea() {
        guard let contentView = self.contentView else { return }

        // Remove old tracking area
        if let existingArea = trackingArea {
            contentView.removeTrackingArea(existingArea)
        }

        // Get current frame based on notch state (collapsed = exact, expanded = with expansion)
        guard let trackingFrame = hitTestManager.getCurrentFrame() else {
            return
        }

        // Create new tracking area with state-appropriate frame
        let newTrackingArea = NSTrackingArea(
            rect: trackingFrame,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )

        contentView.addTrackingArea(newTrackingArea)
        trackingArea = newTrackingArea
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var acceptsMouseMovedEvents: Bool {
        get { return true }
        set { }
    }

    func setupDraggingDestination() {
        self.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
    }

    // Setup custom content view with hit testing
    func setupCustomContentView(hostingView: NSView) {
        let customView = HitTestContentView()
        customView.hitTestManager = hitTestManager
        customView.wantsLayer = true
        customView.layer?.masksToBounds = false

        // Add hosting view as subview
        customView.addSubview(hostingView)
        hostingView.frame = customView.bounds
        hostingView.autoresizingMask = [.width, .height]

        self.contentView = customView
        self.customContentView = customView
    }

    // MARK: - NSDraggingDestination Protocol

    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let location = sender.draggingLocation

        // Check if in zone first
        guard hitTestManager.isInZone(location) else {
            return []
        }

        guard sender.draggingPasteboard.types?.contains(.fileURL) == true else {
            return []
        }

        isCurrentlyDragging = true
        return .copy
    }

    func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard hitTestManager.isInZone(sender.draggingLocation) else {
            return []
        }
        return .copy
    }

    func draggingExited(_ sender: NSDraggingInfo?) {
        isCurrentlyDragging = false
    }

    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isCurrentlyDragging = false
        return hitTestManager.isInZone(sender.draggingLocation)
    }
}

class FloatingWindowManager: ObservableObject {
    static let shared = FloatingWindowManager()

    var panel: NSPanel?
    @Published var isVisible = true

    private var modelContainer: ModelContainer?

    private init() {}

    func createFloatingPanel(modelContainer: ModelContainer) {
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
        // Note: Mouse event handling is done via custom HitTestContentView

        // Hide window controls
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        // Don't hide when clicking elsewhere
        panel.hidesOnDeactivate = false

        // Create NotchView with model container
        let notchView = NotchView()
            .modelContainer(modelContainer)

        // Set SwiftUI content with custom hit testing
        let hostingView = NSHostingView(rootView: notchView)
        hostingView.wantsLayer = true
        hostingView.layer?.masksToBounds = false

        // Setup custom content view with hit testing
        panel.setupCustomContentView(hostingView: hostingView)

        // Setup drag and drop destination
        panel.setupDraggingDestination()

        self.panel = panel

        // Position at notch
        NotchPositioner.positionAtNotch(window: panel)

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
        panel?.makeKeyAndOrderFront(nil)
        panel?.orderFrontRegardless()
        isVisible = true
    }

    func makeKey() {
        panel?.makeKey()
    }

    func hide() {
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
    func setNotchContainerFrame(_ frame: CGRect, notchState: NotchState) {
        guard let panel = panel as? KeyablePanel,
              let contentView = panel.contentView else { return }

        // Convert from SwiftUI flipped coordinates to AppKit non-flipped coordinates
        // SwiftUI: Y=0 at top, grows downward
        // AppKit: Y=0 at bottom, grows upward
        let contentHeight = contentView.bounds.height
        let convertedFrame = CGRect(
            x: frame.origin.x,
            y: contentHeight - frame.origin.y - frame.height,
            width: frame.width,
            height: frame.height
        )

        panel.setNotchContainerFrame(convertedFrame, notchState: notchState)
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

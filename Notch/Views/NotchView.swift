//
//  NotchView.swift
//  Notch
//
//  Created by Nikita Stogniy on 7/11/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum NotchState {
    case collapsed
    case expanded
}

struct NotchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var storedFiles: [StoredFile]
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var moduleManager = ModuleManager.shared

    @State private var notchState: NotchState = .collapsed {
        didSet {
            updateWindowPosition()
        }
    }
    @State private var isHovering = false
    @State private var isDropTargeted = false
    @State private var hoverCollapseTask: Task<Void, Never>?
    @State private var isDraggingFile = false
    @State private var isDraggingFromNotch = false
    @State private var showCalculator = false
    @State private var calculatorKeyPressed: String? = nil
    @State private var currentModuleIndex = 0
    @FocusState private var isFocused: Bool
    @State private var lastEscapeTime: Date? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Visible content area - centered horizontally at TOP
            HStack {
                Spacer()
                notchContainer
                Spacer()
            }

            // Dynamic spacer - pushes content to top and fills remaining space
            Spacer()
                .frame(height: 1200 - contentHeight)
        }
        .coordinateSpace(name: "rootView")
        .background(.clear)
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .onKeyPress { keyPress in
                // Only handle keys when expanded
                guard notchState == .expanded else { return .ignored }

                let key = keyPress.characters

                // Check if this is a calculator key
                let calculatorKeys = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
                                     ".", "+", "-", "*", "/", "="]

                if calculatorKeys.contains(key) ||
                   keyPress.key == .return ||
                   keyPress.key == .escape ||
                   keyPress.key == .delete {

                    // Auto-switch to calculator if not shown
                    if !showCalculator {
                        showCalculator = true
                    }

                    // Handle double ESC to exit calculator
                    if keyPress.key == .escape && showCalculator {
                        let now = Date()
                        if let lastEscape = lastEscapeTime,
                           now.timeIntervalSince(lastEscape) < 0.5 {
                            // Double ESC - exit calculator
                            showCalculator = false
                            lastEscapeTime = nil
                            return .handled
                        } else {
                            // First ESC - clear calculator
                            lastEscapeTime = now
                            calculatorKeyPressed = "\u{1B}"
                            return .handled
                        }
                    }

                    // Reset escape timer for non-escape keys
                    lastEscapeTime = nil

                    // Pass the key to calculator
                    if keyPress.key == .return {
                        calculatorKeyPressed = "\r"
                    } else if keyPress.key == .delete {
                        calculatorKeyPressed = "\u{7F}"
                    } else {
                        calculatorKeyPressed = key
                    }

                    return .handled
                }

                return .ignored
            }
            .onReceive(NotificationCenter.default.publisher(for: .draggingFromNotch)) { _ in
                isDraggingFromNotch = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .draggingFromNotchEnded)) { _ in
                isDraggingFromNotch = false
            }
    }

    // Content size based on state
    private var contentWidth: CGFloat {
        notchState == .collapsed ? settings.collapsedWidth : settings.expandedWidth
    }

    private var contentHeight: CGFloat {
        notchState == .collapsed ? settings.collapsedHeight : settings.expandedHeight
    }

    // Update window position based on content height
    private func updateWindowPosition() {
        FloatingWindowManager.shared.updatePosition(visibleHeight: contentHeight, animated: true)
    }

    @ViewBuilder
    private var notchContainer: some View {
        ZStack {
            // Background with settings-based colors
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: notchState == .collapsed ? settings.cornerRadius : settings.cornerRadius + 6,
                bottomTrailingRadius: notchState == .collapsed ? settings.cornerRadius : settings.cornerRadius + 6,
                topTrailingRadius: 0
            )
                .fill(settings.getBackgroundColor().opacity(settings.notchOpacity))
                .overlay {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: notchState == .collapsed ? settings.cornerRadius : settings.cornerRadius + 6,
                        bottomTrailingRadius: notchState == .collapsed ? settings.cornerRadius : settings.cornerRadius + 6,
                        topTrailingRadius: 0
                    )
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(settings.notchBorderOpacity * 1.5),
                                    .white.opacity(settings.notchBorderOpacity * 0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: notchState == .collapsed ? 0.5 : 1
                        )
                }


            // Content
            VStack(spacing: 0) {
                if notchState == .collapsed {
                    collapsedContent
                        .transition(.opacity)
                } else {
                    expandedContent
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: settings.animationDuration), value: notchState)
            .padding()
        }
        .frame(width: contentWidth, height: contentHeight)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: notchState)
        .overlay(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: FramePreferenceKey.self, value: geometry.frame(in: .named("rootView")))
            }
            .id(notchState) // Force GeometryReader to re-evaluate when state changes
        )
        .onPreferenceChange(FramePreferenceKey.self) { localFrame in
            FloatingWindowManager.shared.setNotchContainerFrame(localFrame, notchState: notchState)
        }
        .onHover { hovering in
            hoverCollapseTask?.cancel()

            if hovering {
                isHovering = true
                notchState = .expanded
                // Auto-focus when hovering
                isFocused = true
            } else {
                hoverCollapseTask = Task {
                    let delay = UInt64(settings.collapseDelay * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: delay)
                    guard !Task.isCancelled else { return }

                    isHovering = false
                    if !isDraggingFile {
                        notchState = .collapsed
                        showCalculator = false  // Reset calculator state on collapse
                        lastEscapeTime = nil  // Reset escape timer
                    }
                }
            }
        }
        .onDrop(of: [.fileURL], delegate: FileDropExpandDelegate(
            modelContext: modelContext,
            isTargeted: $isDropTargeted,
            isDraggingFile: $isDraggingFile,
            notchState: $notchState,
            isDraggingFromNotch: $isDraggingFromNotch
        ))
    }

    // MARK: - Collapsed State
    private var collapsedContent: some View {
        HStack(spacing: 12) {
            // Show modules that have collapsed views
            ForEach(Array(moduleManager.collapsedModules.enumerated()), id: \.element.id) { index, module in
                module.collapsedView()
            }

            Spacer()

            // Legacy file count indicator (if file manager is enabled)
            if settings.fileManagerEnabled {
                HStack(spacing: 4) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 12))
                    Text("\(storedFiles.count)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(settings.getAccentColor())
                .opacity(0.8)
            }
        }
        .foregroundColor(.white)
    }

    // MARK: - Expanded State
    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Module tabs - show if we have multiple modules or legacy modules
            let allModules = moduleManager.enabledModules
            let hasLegacyModules = settings.calculatorEnabled || settings.fileManagerEnabled
            let hasMultipleOptions = allModules.count + (hasLegacyModules ? 1 : 0) > 1

            if hasMultipleOptions {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // New modules
                        ForEach(Array(allModules.enumerated()), id: \.element.id) { index, module in
                            ModuleTabButton(
                                title: module.name,
                                icon: module.icon,
                                isSelected: currentModuleIndex == index && !showCalculator,
                                action: {
                                    currentModuleIndex = index
                                    showCalculator = false
                                }
                            )
                        }

                        // Legacy modules button
                        if hasLegacyModules {
                            ModuleTabButton(
                                title: settings.calculatorEnabled && settings.fileManagerEnabled ? "Legacy" : (settings.calculatorEnabled ? "Calculator" : "Files"),
                                icon: "square.grid.2x2",
                                isSelected: showCalculator || (allModules.isEmpty && hasLegacyModules),
                                action: {
                                    showCalculator = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(height: 36)
            }

            // Content
            Group {
                if showCalculator || (allModules.isEmpty && hasLegacyModules) {
                    // Show legacy module UI
                    legacyModuleContent
                } else if !allModules.isEmpty, currentModuleIndex < allModules.count {
                    // Show selected module
                    allModules[currentModuleIndex].expandedView()
                } else {
                    // No modules enabled
                    VStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No modules enabled")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Enable modules in Settings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .animation(.easeInOut(duration: settings.animationDuration), value: showCalculator)
            .animation(.easeInOut(duration: settings.animationDuration), value: currentModuleIndex)
        }
    }

    // Legacy module content (calculator/file manager)
    @ViewBuilder
    private var legacyModuleContent: some View {
        VStack(spacing: 0) {
            // Switch button if both are enabled
            if settings.calculatorEnabled && settings.fileManagerEnabled {
                HStack {
                    Button(action: {
                        showCalculator.toggle()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: showCalculator ? "arrow.left" : "function")
                                .font(.system(size: 10))
                            Text(showCalculator ? "Back to files" : "Calculator")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(settings.getAccentColor().opacity(0.2))
                        )
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.bottom, 8)
                .frame(height: 28)
            }

            // Legacy content
            if settings.calculatorEnabled && showCalculator {
                CalculatorView(keyPressed: $calculatorKeyPressed)
            } else if settings.fileManagerEnabled {
                FileManagerView(isDropTargeted: $isDropTargeted)
            } else if settings.calculatorEnabled {
                CalculatorView(keyPressed: $calculatorKeyPressed)
            }
        }
    }
}

// MARK: - Module Tab Button
struct ModuleTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? settings.getAccentColor().opacity(0.3) : Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preference Key for Frame Tracking
struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

#Preview {
    NotchView()
        .modelContainer(for: StoredFile.self, inMemory: true)
        .frame(width: 800, height: 600)
        .background(.black)
}

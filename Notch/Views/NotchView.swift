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
                    .onAppear {
                        print("📐 [NotchView] GeometryReader onAppear")
                    }
            }
            .id(notchState) // Force GeometryReader to re-evaluate when state changes
        )
        .onPreferenceChange(FramePreferenceKey.self) { localFrame in
            // localFrame is in rootView coordinates (SwiftUI coordinates)
            // NSHostingView uses flipped coordinates (same as SwiftUI), so we can use it directly
            // No need to convert to AppKit coordinates for NSTrackingArea

            print("📐 [NotchView] State: \(notchState), contentSize: \(contentWidth)x\(contentHeight)")
            print("📐 [NotchView] SwiftUI localFrame: \(localFrame)")

            FloatingWindowManager.shared.setNotchContainerFrame(localFrame, notchState: notchState)
        }
        .onChange(of: notchState) { _, newState in
            print("📐 [NotchView] notchState changed to: \(newState)")
            // Force tracking area update by triggering preference change
            // This ensures tracking area updates even if GeometryReader doesn't fire
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
            // Calculator button on left - only show if enabled
            if settings.calculatorEnabled {
                Button(action: {
                    showCalculator = true
                    notchState = .expanded
                }) {
                    Image(systemName: "function")
                        .font(.system(size: 12))
                        .foregroundColor(settings.getAccentColor().opacity(0.8))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }

            Spacer()

            // File count indicator on right - only show if file manager enabled
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
            // Top bar with switch button - only show if both modules enabled
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

            // Content
            Group {
                if settings.calculatorEnabled && showCalculator {
                    CalculatorView(keyPressed: $calculatorKeyPressed)
                } else if settings.fileManagerEnabled {
                    FileManagerView(isDropTargeted: $isDropTargeted)
                } else if settings.calculatorEnabled {
                    CalculatorView(keyPressed: $calculatorKeyPressed)
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
        }
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

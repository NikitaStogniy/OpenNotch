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

    @State private var notchState: NotchState = .collapsed {
        didSet {
            updateWindowSize()
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
        notchContainer
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
            .onHover { hovering in
                hoverCollapseTask?.cancel()

                if hovering {
                    isHovering = true
                    notchState = .expanded
                    // Auto-focus when hovering
                    isFocused = true
                } else {
                    hoverCollapseTask = Task {
                        try? await Task.sleep(nanoseconds: 250_000_000)
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
            .onReceive(NotificationCenter.default.publisher(for: .draggingFromNotch)) { _ in
                isDraggingFromNotch = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .draggingFromNotchEnded)) { _ in
                isDraggingFromNotch = false
            }
    }

    private func updateWindowSize() {
        let size = notchState.windowSize
        FloatingWindowManager.shared.updateSize(width: size.width, height: size.height, animated: true, resetPosition: true)
    }

    @ViewBuilder
    private var notchContainer: some View {
        ZStack {
            // Black background
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: notchState == .collapsed ? 18 : 24,
                bottomTrailingRadius: notchState == .collapsed ? 18 : 24,
                topTrailingRadius: 0
            )
                .fill(Color.black)
                .overlay {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: notchState == .collapsed ? 18 : 24,
                        bottomTrailingRadius: notchState == .collapsed ? 18 : 24,
                        topTrailingRadius: 0
                    )
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .white.opacity(0.05)],
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
            .animation(.easeOut(duration: 0.25), value: notchState)
            .padding()
        }
        .frame(
            width: notchState == .collapsed ? 310 : 680,
            height: notchState == .collapsed ? 40 : 360
        )
    }

    // MARK: - Collapsed State
    private var collapsedContent: some View {
        HStack(spacing: 12) {
            // Calculator button on left
            Button(action: {
                showCalculator = true
                notchState = .expanded
            }) {
                Image(systemName: "function")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            Spacer()

            // File count indicator on right
            HStack(spacing: 4) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 12))
                Text("\(storedFiles.count)")
                    .font(.system(size: 12, weight: .semibold))
            }
            .opacity(0.8)
        }
        .foregroundColor(.white)
    }

    // MARK: - Expanded State
    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Top bar with switch button
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
                            .fill(Color.white.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.bottom, 8)
            .frame(height: 28)

            // Content
            Group {
                if showCalculator {
                    CalculatorView(keyPressed: $calculatorKeyPressed)
                } else {
                    FileManagerView(isDropTargeted: $isDropTargeted)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showCalculator)
        }
    }
}

#Preview {
    NotchView()
        .modelContainer(for: StoredFile.self, inMemory: true)
        .frame(width: 800, height: 600)
        .background(.black)
}

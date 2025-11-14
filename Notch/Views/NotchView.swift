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
    @State private var currentModuleIndex = 0

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
                        .padding(.horizontal, settings.collapsedPadding)
                        .transition(.opacity)
                } else {
                    expandedContent
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: settings.animationDuration), value: notchState)
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
            } else {
                hoverCollapseTask = Task {
                    let delay = UInt64(settings.collapseDelay * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: delay)
                    guard !Task.isCancelled else { return }

                    isHovering = false
                    if !isDraggingFile {
                        notchState = .collapsed
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
        HStack(spacing: 8) {
            // Left side modules
            ForEach(Array(moduleManager.leftModules.enumerated()), id: \.element.id) { index, module in
                Button(action: {
                    // Expand notch and select this module
                    if let moduleIndex = moduleManager.enabledModules.firstIndex(where: { $0.id == module.id }) {
                        currentModuleIndex = moduleIndex
                        notchState = .expanded
                    }
                }) {
                    AnyView(module.collapsedView())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Right side modules
            ForEach(Array(moduleManager.rightModules.enumerated()), id: \.element.id) { index, module in
                Button(action: {
                    // Expand notch and select this module
                    if let moduleIndex = moduleManager.enabledModules.firstIndex(where: { $0.id == module.id }) {
                        currentModuleIndex = moduleIndex
                        notchState = .expanded
                    }
                }) {
                    AnyView(module.collapsedView())
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundColor(.white)
    }

    // MARK: - Expanded State
    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Module tabs - show if we have multiple modules
            let allModules = moduleManager.enabledModules
            let hasMultipleOptions = allModules.count > 1

            if hasMultipleOptions {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Modules - using mini icons
                        ForEach(Array(allModules.enumerated()), id: \.element.id) { index, module in
                            ModuleTabButton(
                                title: module.name,
                                icon: module.miniIcon,
                                isSelected: currentModuleIndex == index,
                                iconOnly: true,
                                action: {
                                    currentModuleIndex = index
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
                if !allModules.isEmpty, currentModuleIndex < allModules.count {
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
                            Text("notch.empty.title")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("notch.empty.message")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .animation(.easeInOut(duration: settings.animationDuration), value: currentModuleIndex)
        }
    }

}

// MARK: - Module Tab Button
struct ModuleTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var iconOnly: Bool = false
    let action: () -> Void

    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        Button(action: action) {
            if iconOnly {
                // Icon-only mode - just show the icon
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(isSelected ? settings.getAccentColor().opacity(0.3) : Color.white.opacity(0.05))
                    )
            } else {
                // Full mode - show icon and text
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
        }
        .buttonStyle(.plain)
        .help(title) // Tooltip showing full name
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

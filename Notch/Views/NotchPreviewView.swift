//
//  NotchPreviewView.swift
//  Notch
//
//  Created by Nikita Stogniy on 11/11/25.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

struct NotchPreviewView: View {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var moduleManager = ModuleManager.shared

    @State private var leftModuleIds: [String] = []
    @State private var rightModuleIds: [String] = []
    @State private var disabledModuleIds: [String] = []

    // Drag state
    @State private var draggedModuleId: String? = nil
    @State private var dropTarget: DropTarget? = nil
    @State private var hoverIndex: HoverIndex? = nil

    enum DropTarget: Equatable {
        case leftSide(Int)
        case rightSide(Int)
        case disabledZone
    }

    struct HoverIndex: Equatable {
        let side: ModuleSide
        let index: Int
    }

    // MARK: - Overflow Detection
    private let iconWidth: CGFloat = 28
    private let iconSpacing: CGFloat = 4
    private let physicalNotchWidth: CGFloat = 155 // ~50% of collapsed width

    private var maxSafeWidthPerSide: CGFloat {
        (settings.collapsedWidth - physicalNotchWidth - (settings.collapsedPadding * 2)) / 2
    }

    private var leftSideWidth: CGFloat {
        CGFloat(leftModuleIds.count) * (iconWidth + iconSpacing) - (leftModuleIds.isEmpty ? 0 : iconSpacing)
    }

    private var rightSideWidth: CGFloat {
        CGFloat(rightModuleIds.count) * (iconWidth + iconSpacing) - (rightModuleIds.isEmpty ? 0 : iconSpacing)
    }

    private var isLeftOverflowing: Bool {
        leftSideWidth > maxSafeWidthPerSide
    }

    private var isRightOverflowing: Bool {
        rightSideWidth > maxSafeWidthPerSide
    }

    private var hasOverflow: Bool {
        isLeftOverflowing || isRightOverflowing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Module Arrangement")
                .font(.headline)
                .foregroundColor(.primary)

            // Collapsed notch preview
            notchView

            // Disabled modules drop zone
            disabledZoneView

            // Instructions
            Text("Drag icons to arrange, or drag to bottom to disable")
                .font(.caption)
                .foregroundColor(.secondary)

            // Overflow warning
            if hasOverflow {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Too many modules!")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)

                        if isLeftOverflowing && isRightOverflowing {
                            Text("Some modules on both sides will be hidden behind the physical notch")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else if isLeftOverflowing {
                            Text("Some modules on the left will be hidden behind the physical notch")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Some modules on the right will be hidden behind the physical notch")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .onAppear {
            loadCurrentArrangement()
        }
    }

    // MARK: - Notch View
    private var notchView: some View {
        ZStack {
            // Background
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: settings.cornerRadius,
                bottomTrailingRadius: settings.cornerRadius,
                topTrailingRadius: 0
            )
            .fill(settings.getBackgroundColor().opacity(settings.notchOpacity))
            .overlay {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: settings.cornerRadius,
                    bottomTrailingRadius: settings.cornerRadius,
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
                    lineWidth: 0.5
                )
            }

            // Content with mini icons
            HStack(spacing: 0) {
                // Left side modules
                HStack(spacing: 4) {
                    ForEach(Array(leftModuleIds.enumerated()), id: \.element) { index, moduleId in
                        if let module = moduleManager.getModule(by: moduleId) {
                            // Placeholder for drop position
                            if draggedModuleId != nil && hoverIndex?.side == .left && hoverIndex?.index == index {
                                dropPlaceholder
                            }

                            if draggedModuleId != moduleId {
                                miniIconView(for: module, side: .left, index: index)
                                    .offset(x: offsetForModule(moduleId, side: .left, index: index))
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hoverIndex)
                            }
                        }
                    }

                    // End placeholder for left side
                    if draggedModuleId != nil && hoverIndex?.side == .left && hoverIndex?.index == leftModuleIds.count {
                        dropPlaceholder
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Right side modules
                HStack(spacing: 4) {
                    // Start placeholder for right side
                    if draggedModuleId != nil && hoverIndex?.side == .right && hoverIndex?.index == 0 {
                        dropPlaceholder
                    }

                    ForEach(Array(rightModuleIds.enumerated()), id: \.element) { index, moduleId in
                        if let module = moduleManager.getModule(by: moduleId) {
                            if draggedModuleId != moduleId {
                                miniIconView(for: module, side: .right, index: index)
                                    .offset(x: offsetForModule(moduleId, side: .right, index: index))
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hoverIndex)
                            }

                            // Placeholder after this icon
                            if draggedModuleId != nil && hoverIndex?.side == .right && hoverIndex?.index == index + 1 {
                                dropPlaceholder
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, settings.collapsedPadding)

            // Physical notch overlay - show when overflow
            if hasOverflow {
                physicalNotchOverlay
            }

            // Overflow indicators
            if isLeftOverflowing {
                leftOverflowIndicator
            }
            if isRightOverflowing {
                rightOverflowIndicator
            }
        }
        .frame(width: settings.collapsedWidth, height: settings.collapsedHeight)
        .overlay {
            // Border highlight for overflow
            if hasOverflow {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: settings.cornerRadius,
                    bottomTrailingRadius: settings.cornerRadius,
                    topTrailingRadius: 0
                )
                .stroke(Color.orange, lineWidth: 2)
                .animation(.easeInOut(duration: 0.3), value: hasOverflow)
            }
        }
        .background(
            // Global drop zone for notch
            GeometryReader { geometry in
                Color.clear
                    .onDrop(of: [.text], isTargeted: nil) { providers, location in
                        handleNotchDrop(providers: providers, location: location, geometry: geometry)
                    }
            }
        )
    }

    // MARK: - Disabled Zone View
    private var disabledZoneView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Disabled Modules")
                .font(.caption)
                .foregroundColor(.secondary)

            ZStack {
                // Dashed border container
                RoundedRectangle(cornerRadius: 8)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundColor(dropTarget == .disabledZone ? settings.getAccentColor() : .secondary.opacity(0.3))
                    .frame(height: 60)
                    .animation(.easeInOut(duration: 0.2), value: dropTarget)

                // Content
                if disabledModuleIds.isEmpty && draggedModuleId == nil {
                    Text("Drop here to disable")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.5))
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(disabledModuleIds, id: \.self) { moduleId in
                                if let module = moduleManager.getModule(by: moduleId) {
                                    if draggedModuleId != moduleId {
                                        disabledIconView(for: module)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .onDrop(of: [.text], isTargeted: Binding(
                get: { dropTarget == .disabledZone },
                set: { isTargeted in
                    if isTargeted && draggedModuleId != nil {
                        dropTarget = .disabledZone
                    } else if !isTargeted && dropTarget == .disabledZone {
                        dropTarget = nil
                    }
                }
            )) { providers in
                handleDisabledZoneDrop(providers: providers)
            }
        }
    }

    // MARK: - Physical Notch Overlay
    private var physicalNotchOverlay: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 10,
            bottomTrailingRadius: 10,
            topTrailingRadius: 0
        )
        .fill(Color.black.opacity(0.6))
        .frame(width: physicalNotchWidth, height: settings.collapsedHeight)
        .overlay(
            Text("Physical Notch")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .offset(y: 8)
        )
    }

    // MARK: - Overflow Indicators
    private var leftOverflowIndicator: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundColor(.orange)
                .padding(4)
                .background(Circle().fill(Color.black.opacity(0.3)))
            Spacer()
        }
        .padding(.leading, 8)
    }

    private var rightOverflowIndicator: some View {
        HStack {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundColor(.orange)
                .padding(4)
                .background(Circle().fill(Color.black.opacity(0.3)))
        }
        .padding(.trailing, 8)
    }

    // MARK: - Drop Placeholder
    private var dropPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(style: StrokeStyle(lineWidth: 2, dash: [4]))
            .foregroundColor(settings.getAccentColor())
            .frame(width: 28, height: 28)
            .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Mini Icon View
    private func miniIconView(for module: any NotchModule, side: ModuleSide, index: Int) -> some View {
        Image(systemName: module.miniIcon)
            .font(.system(size: 16))
            .foregroundColor(.white.opacity(draggedModuleId != nil ? 0.6 : 1.0))
            .frame(width: 20, height: 20)
            .padding(4)
            .background(
                Circle()
                    .fill(Color.white.opacity(0.1))
            )
            .contentShape(Circle())
            .help(module.name)
            .onDrag {
                draggedModuleId = module.id
                return NSItemProvider(object: module.id as NSString)
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    if draggedModuleId != nil && draggedModuleId != module.id {
                        withAnimation {
                            // Determine if we should insert before or after
                            let shouldInsertBefore = location.x < 14 // Half of icon width
                            hoverIndex = HoverIndex(side: side, index: shouldInsertBefore ? index : index + 1)
                        }
                    }
                case .ended:
                    break
                }
            }
    }

    // MARK: - Disabled Icon View
    private func disabledIconView(for module: any NotchModule) -> some View {
        Image(systemName: module.miniIcon)
            .font(.system(size: 14))
            .foregroundColor(.secondary)
            .frame(width: 18, height: 18)
            .padding(4)
            .background(
                Circle()
                    .fill(Color.secondary.opacity(0.1))
            )
            .help(module.name)
            .onDrag {
                draggedModuleId = module.id
                return NSItemProvider(object: module.id as NSString)
            }
    }

    // MARK: - Drop Handlers
    private func handleNotchDrop(providers: [NSItemProvider], location: CGPoint, geometry: GeometryProxy) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { (item, error) in
            guard let data = item as? Data,
                  let moduleId = String(data: data, encoding: .utf8) else { return }

            DispatchQueue.main.async {
                if let index = hoverIndex {
                    // Insert at specific position
                    moveModuleToSide(moduleId: moduleId, side: index.side, atIndex: index.index)
                } else {
                    // Fallback: insert at end of closest side
                    let side: ModuleSide = location.x < geometry.size.width / 2 ? .left : .right
                    if side == .left {
                        moveModuleToSide(moduleId: moduleId, side: .left, atIndex: leftModuleIds.count)
                    } else {
                        moveModuleToSide(moduleId: moduleId, side: .right, atIndex: rightModuleIds.count)
                    }
                }

                draggedModuleId = nil
                hoverIndex = nil
                dropTarget = nil
            }
        }

        return true
    }

    private func handleDisabledZoneDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { (item, error) in
            guard let data = item as? Data,
                  let moduleId = String(data: data, encoding: .utf8) else { return }

            DispatchQueue.main.async {
                disableModule(moduleId: moduleId)
                draggedModuleId = nil
                hoverIndex = nil
                dropTarget = nil
            }
        }

        return true
    }

    // MARK: - Helper Functions
    private func offsetForModule(_ moduleId: String, side: ModuleSide, index: Int) -> CGFloat {
        guard let hover = hoverIndex, hover.side == side, draggedModuleId != moduleId else {
            return 0
        }

        // Make space when hovering
        if index >= hover.index {
            return 32 // Shift right to make space
        }

        return 0
    }

    /// Load the current arrangement from settings
    private func loadCurrentArrangement() {
        let allModules = moduleManager.availableModules

        // Separate enabled and disabled
        let enabled = allModules.filter { $0.isEnabled }
        let disabled = allModules.filter { !$0.isEnabled }

        // Initialize from saved settings or defaults
        var tempLeft: [String] = []
        var tempRight: [String] = []

        for module in enabled {
            let side = moduleManager.getEffectiveSide(for: module)
            if side == .left {
                tempLeft.append(module.id)
            } else {
                tempRight.append(module.id)
            }
        }

        // Sort by saved order or priority
        leftModuleIds = sortByOrder(tempLeft, orderArray: settings.moduleOrderLeft)
        rightModuleIds = sortByOrder(tempRight, orderArray: settings.moduleOrderRight)
        disabledModuleIds = disabled.map { $0.id }
    }

    /// Sort module IDs by saved order or priority
    private func sortByOrder(_ ids: [String], orderArray: [String]) -> [String] {
        if orderArray.isEmpty {
            return ids.sorted { id1, id2 in
                let module1 = moduleManager.getModule(by: id1)
                let module2 = moduleManager.getModule(by: id2)
                return (module1?.priority ?? 0) > (module2?.priority ?? 0)
            }
        }

        return ids.sorted { id1, id2 in
            let index1 = orderArray.firstIndex(of: id1) ?? Int.max
            let index2 = orderArray.firstIndex(of: id2) ?? Int.max
            return index1 < index2
        }
    }

    /// Move module to a specific side and index
    private func moveModuleToSide(moduleId: String, side: ModuleSide, atIndex index: Int) {
        // Enable the module if it was disabled
        if disabledModuleIds.contains(moduleId) {
            disabledModuleIds.removeAll { $0 == moduleId }
            enableModule(moduleId: moduleId)
        }

        // Remove from both sides
        leftModuleIds.removeAll { $0 == moduleId }
        rightModuleIds.removeAll { $0 == moduleId }

        // Add to the target side at the specified index
        if side == .left {
            leftModuleIds.insert(moduleId, at: min(index, leftModuleIds.count))
        } else {
            rightModuleIds.insert(moduleId, at: min(index, rightModuleIds.count))
        }

        saveArrangement()
    }

    /// Disable a module
    private func disableModule(moduleId: String) {
        // Remove from enabled sides
        leftModuleIds.removeAll { $0 == moduleId }
        rightModuleIds.removeAll { $0 == moduleId }

        // Add to disabled
        if !disabledModuleIds.contains(moduleId) {
            disabledModuleIds.append(moduleId)
        }

        // Toggle in module manager
        moduleManager.toggleModule(id: moduleId)

        saveArrangement()
    }

    /// Enable a module (called when dragging from disabled zone)
    private func enableModule(moduleId: String) {
        moduleManager.toggleModule(id: moduleId)
    }

    /// Save the current arrangement to settings
    private func saveArrangement() {
        // Update side assignments
        var assignments: [String: ModuleSide] = [:]
        for id in leftModuleIds {
            assignments[id] = .left
        }
        for id in rightModuleIds {
            assignments[id] = .right
        }
        settings.moduleSideAssignments = assignments

        // Update order
        settings.moduleOrderLeft = leftModuleIds
        settings.moduleOrderRight = rightModuleIds

        // Notify module manager to refresh
        moduleManager.objectWillChange.send()
    }
}

#Preview {
    NotchPreviewView()
        .padding()
        .frame(width: 500, height: 250)
        .background(Color(NSColor.windowBackgroundColor))
}

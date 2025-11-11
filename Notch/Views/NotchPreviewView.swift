//
//  NotchPreviewView.swift
//  Notch
//
//  Created by Nikita Stogniy on 11/11/25.
//

import SwiftUI

struct NotchPreviewView: View {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var moduleManager = ModuleManager.shared
    @State private var isExpanded = false

    private let scale: CGFloat = 0.4 // Scale down for preview

    var body: some View {
        VStack(spacing: 12) {
            Text("Preview")
                .font(.headline)
                .foregroundColor(.primary)

            // Preview container with screen representation
            ZStack {
                // Screen background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.9))
                    .frame(width: 300, height: 200)

                // Menu bar representation
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 300, height: 24)
                    .position(x: 150, y: 12)

                // Notch preview
                VStack(spacing: 0) {
                    notchPreview
                        .onHover { hovering in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isExpanded = hovering
                            }
                        }

                    Spacer()
                }
                .frame(width: 300, height: 200)
            }
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )

            // Instructions
            Text("Hover to preview expansion")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    @ViewBuilder
    private var notchPreview: some View {
        let width = isExpanded ? settings.expandedWidth * scale : settings.collapsedWidth * scale
        let height = isExpanded ? settings.expandedHeight * scale : settings.collapsedHeight * scale

        ZStack {
            // Background
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: (isExpanded ? settings.cornerRadius + 6 : settings.cornerRadius) * scale,
                bottomTrailingRadius: (isExpanded ? settings.cornerRadius + 6 : settings.cornerRadius) * scale,
                topTrailingRadius: 0
            )
            .fill(settings.getBackgroundColor().opacity(settings.notchOpacity))
            .overlay {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: (isExpanded ? settings.cornerRadius + 6 : settings.cornerRadius) * scale,
                    bottomTrailingRadius: (isExpanded ? settings.cornerRadius + 6 : settings.cornerRadius) * scale,
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
                    lineWidth: isExpanded ? 0.4 : 0.2
                )
            }

            // Content preview
            if isExpanded {
                expandedContentPreview
            } else {
                collapsedContentPreview
            }
        }
        .frame(width: width, height: height)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
    }

    @ViewBuilder
    private var collapsedContentPreview: some View {
        HStack(spacing: 6) {
            // Show enabled modules in collapsed view
            ForEach(moduleManager.collapsedModules, id: \.id) { module in
                module.collapsedView()
                    .scaleEffect(scale)
            }

            Spacer()

            // Indicator
            HStack(spacing: 2) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 4))
                Text("2")
                    .font(.system(size: 6, weight: .semibold))
            }
            .foregroundColor(settings.getAccentColor())
            .opacity(0.6)
        }
        .padding(6)
    }

    @ViewBuilder
    private var expandedContentPreview: some View {
        VStack(spacing: 4) {
            // Module preview
            if let firstModule = moduleManager.enabledModules.first {
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: firstModule.icon)
                            .font(.system(size: 8))
                            .foregroundColor(settings.getAccentColor())
                        Text(firstModule.name)
                            .font(.system(size: 6, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                    }

                    // Placeholder content
                    VStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 8)
                        }
                    }
                }
                .padding(6)
            } else {
                Text("No modules")
                    .font(.system(size: 6))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    NotchPreviewView()
        .frame(width: 400, height: 350)
        .background(Color(NSColor.windowBackgroundColor))
}

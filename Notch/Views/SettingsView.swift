//
//  SettingsView.swift
//  Notch
//
//  Created by Nikita Stogniy on 8/11/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var selectedTab: SettingsTab = .appearance

    enum SettingsTab: String, CaseIterable, Identifiable {
        case appearance = "Appearance"
        case modules = "Modules"
        case behavior = "Behavior"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .appearance: return "paintbrush.fill"
            case .modules: return "square.grid.2x2.fill"
            case .behavior: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .navigationSplitViewColumnWidth(min: 150, ideal: 180, max: 200)
            .listStyle(.sidebar)
        } detail: {
            // Detail View
            ScrollView {
                VStack(spacing: 0) {
                    switch selectedTab {
                    case .appearance:
                        AppearanceSettingsView()
                    case .modules:
                        ModulesSettingsView()
                    case .behavior:
                        BehaviorSettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .navigationTitle("Settings")
        .frame(minWidth: 650, minHeight: 450)
    }
}

// MARK: - Appearance Settings
struct AppearanceSettingsView: View {
    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SettingsSection(title: "Colors", icon: "paintpalette.fill") {
                VStack(alignment: .leading, spacing: 16) {
                    // Background Color
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Background Color")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("", selection: $settings.notchBackgroundColor) {
                            HStack {
                                Circle()
                                    .fill(.black)
                                    .frame(width: 16, height: 16)
                                Text("Black")
                            }.tag("black")

                            HStack {
                                Circle()
                                    .fill(Color(white: 0.15))
                                    .frame(width: 16, height: 16)
                                Text("Dark Gray")
                            }.tag("gray")

                            HStack {
                                Circle()
                                    .fill(Color(red: 0.05, green: 0.05, blue: 0.15))
                                    .frame(width: 16, height: 16)
                                Text("Dark Blue")
                            }.tag("blue")

                            HStack {
                                Circle()
                                    .fill(Color(red: 0.1, green: 0.05, blue: 0.15))
                                    .frame(width: 16, height: 16)
                                Text("Dark Purple")
                            }.tag("purple")
                        }
                        .pickerStyle(.radioGroup)
                    }

                    Divider()

                    // Accent Color
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accent Color")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("", selection: $settings.accentColor) {
                            HStack {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 16, height: 16)
                                Text("Blue")
                            }.tag("blue")

                            HStack {
                                Circle()
                                    .fill(.purple)
                                    .frame(width: 16, height: 16)
                                Text("Purple")
                            }.tag("purple")

                            HStack {
                                Circle()
                                    .fill(.pink)
                                    .frame(width: 16, height: 16)
                                Text("Pink")
                            }.tag("pink")

                            HStack {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 16, height: 16)
                                Text("Green")
                            }.tag("green")

                            HStack {
                                Circle()
                                    .fill(.orange)
                                    .frame(width: 16, height: 16)
                                Text("Orange")
                            }.tag("orange")
                        }
                        .pickerStyle(.radioGroup)
                    }
                }
            }

            SettingsSection(title: "Opacity", icon: "circle.lefthalf.filled") {
                VStack(alignment: .leading, spacing: 16) {
                    // Background Opacity
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Background Opacity")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(settings.notchOpacity * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }

                        Slider(value: $settings.notchOpacity, in: 0.5...1.0, step: 0.05)
                    }

                    Divider()

                    // Border Opacity
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Border Opacity")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(settings.notchBorderOpacity * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }

                        Slider(value: $settings.notchBorderOpacity, in: 0.0...0.5, step: 0.05)
                    }
                }
            }

            SettingsSection(title: "Size", icon: "arrow.up.left.and.arrow.down.right") {
                VStack(alignment: .leading, spacing: 16) {
                    // Corner Radius
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Corner Radius")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(settings.cornerRadius))pt")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }

                        Slider(value: $settings.cornerRadius, in: 8...32, step: 2)
                    }

                    Divider()

                    Text("Advanced size settings")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Collapsed Width")
                            Spacer()
                            Text("\(Int(settings.collapsedWidth))pt")
                                .monospacedDigit()
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        Slider(value: $settings.collapsedWidth, in: 200...400, step: 10)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Collapsed Height")
                            Spacer()
                            Text("\(Int(settings.collapsedHeight))pt")
                                .monospacedDigit()
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        Slider(value: $settings.collapsedHeight, in: 30...100, step: 5)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Expanded Width")
                            Spacer()
                            Text("\(Int(settings.expandedWidth))pt")
                                .monospacedDigit()
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        Slider(value: $settings.expandedWidth, in: 500...800, step: 10)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Expanded Height")
                            Spacer()
                            Text("\(Int(settings.expandedHeight))pt")
                                .monospacedDigit()
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        Slider(value: $settings.expandedHeight, in: 300...1000, step: 10)
                    }
                }
            }

            Spacer()

            // Reset Button
            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        settings.resetToDefaults()
                    }
                }) {
                    Text("Reset to Defaults")
                }
            }
        }
        .padding(24)
    }
}

// MARK: - Modules Settings
struct ModulesSettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var moduleManager = ModuleManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Preview Section
            HStack {
                Spacer()
                NotchPreviewView()
                Spacer()
            }

            // New Module System
            SettingsSection(title: "New Modules", icon: "sparkles") {
                VStack(alignment: .leading, spacing: 16) {
                    if moduleManager.availableModules.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "info.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("No new modules yet")
                                        .font(.headline)
                                    Text("New modules will appear here")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding()
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(8)
                        }
                    } else {
                        ForEach(Array(moduleManager.availableModules.enumerated()), id: \.element.id) { index, module in
                            DynamicModuleToggle(module: module)

                            if index < moduleManager.availableModules.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }

            // Legacy Modules
            SettingsSection(title: "Legacy Modules", icon: "square.grid.2x2.fill") {
                VStack(alignment: .leading, spacing: 16) {
                    // Calculator Module
                    ModuleToggle(
                        title: "Calculator",
                        description: "Quick calculator accessible via keyboard shortcuts",
                        icon: "function",
                        isEnabled: $settings.calculatorEnabled
                    )

                    Divider()

                    // File Manager Module
                    ModuleToggle(
                        title: "File Manager",
                        description: "Drag and drop files for quick access",
                        icon: "folder.fill",
                        isEnabled: $settings.fileManagerEnabled
                    )
                }
            }

            Spacer()
        }
        .padding(24)
    }
}

// MARK: - Dynamic Module Toggle
struct DynamicModuleToggle: View {
    let module: any NotchModule
    @StateObject private var moduleManager = ModuleManager.shared

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: module.icon)
                .font(.title2)
                .foregroundColor(module.isEnabled ? .accentColor : .secondary)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(module.name)
                    .font(.headline)
                Text(getModuleDescription())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { module.isEnabled },
                set: { _ in
                    moduleManager.toggleModule(id: module.id)
                }
            ))
            .toggleStyle(.switch)
        }
    }

    private func getModuleDescription() -> String {
        // Return specific descriptions for known modules
        switch module.id {
        case "calendar":
            return "View your calendar events and appointments"
        default:
            return "Custom module"
        }
    }
}

// MARK: - Behavior Settings
struct BehaviorSettingsView: View {
    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SettingsSection(title: "Interaction", icon: "hand.tap.fill") {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Auto-expand on hover", isOn: $settings.autoExpandOnHover)
                        .toggleStyle(.switch)

                    if settings.autoExpandOnHover {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Collapse Delay")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(settings.collapseDelay, specifier: "%.2f")s")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }

                            Slider(value: $settings.collapseDelay, in: 0.1...2.0, step: 0.05)
                        }
                        .padding(.leading, 20)
                    }
                }
            }

            SettingsSection(title: "Animations", icon: "wand.and.stars") {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Animation Duration")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(settings.animationDuration, specifier: "%.2f")s")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }

                        Slider(value: $settings.animationDuration, in: 0.1...0.8, step: 0.05)
                    }
                }
            }

            Spacer()
        }
        .padding(24)
    }
}

// MARK: - Helper Views
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            content
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
        }
    }
}

struct ModuleToggle: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isEnabled ? .accentColor : .secondary)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
        }
    }
}

#Preview {
    SettingsView()
        .frame(width: 700, height: 500)
}

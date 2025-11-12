//
//  SettingsView.swift
//  Notch
//
//  Created by Nikita Stogniy on 8/11/25.
//

import SwiftUI
import UniformTypeIdentifiers

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
    private let themeManager = ThemeManager.shared

    @State private var themeName: String = "My Theme"
    @State private var showExportSuccess = false
    @State private var showImportError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Tab Description
            VStack(alignment: .leading, spacing: 4) {
                Text("Appearance")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Customize the visual appearance of your notch")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)

            // Theme Management Section
            SettingsSection(
                title: "Theme",
                icon: "paintbrush.pointed.fill",
                description: "Save and load your appearance settings as themes"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    // Theme Name
                    HStack {
                        Text("Theme Name")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("Enter theme name", text: $themeName)
                            .textFieldStyle(.roundedBorder)
                    }

                    Divider()

                    // Export/Import Buttons
                    HStack(spacing: 12) {
                        Button(action: exportTheme) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export Theme")
                            }
                        }
                        .buttonStyle(.bordered)

                        Button(action: importTheme) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Import Theme")
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    // Success/Error Messages
                    if showExportSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Theme exported successfully!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if showImportError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // Preset Themes
                    Text("Preset Themes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(ThemeManager.presetThemes) { theme in
                            Button(action: {
                                applyPresetTheme(theme)
                            }) {
                                VStack(spacing: 8) {
                                    HStack {
                                        Circle()
                                            .fill(getThemeColor(theme.notchBackgroundColor))
                                            .frame(width: 16, height: 16)
                                        Circle()
                                            .fill(getThemeColor(theme.accentColor))
                                            .frame(width: 16, height: 16)
                                    }
                                    Text(theme.name)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Simple/Advanced Mode Toggle
            HStack {
                Text("Settings Mode")
                    .font(.headline)
                Spacer()
                Picker("", selection: $settings.isAdvancedMode) {
                    Text("Simple").tag(false)
                    Text("Advanced").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding()
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)

            SettingsSection(
                title: "Colors",
                icon: "paintpalette.fill",
                description: "Choose the color scheme for your notch background and accent elements"
            ) {
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

            SettingsSection(
                title: "Opacity",
                icon: "circle.lefthalf.filled",
                description: "Adjust transparency levels for the notch background and border"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    if settings.isAdvancedMode {
                        // Advanced Mode: Text Input Fields
                        NumberInputField(
                            title: "Background Opacity",
                            value: Binding(
                                get: { settings.notchOpacity * 100 },
                                set: { settings.notchOpacity = $0 / 100 }
                            ),
                            unit: "%",
                            min: 50,
                            max: 100,
                            step: 5
                        )

                        Divider()

                        NumberInputField(
                            title: "Border Opacity",
                            value: Binding(
                                get: { settings.notchBorderOpacity * 100 },
                                set: { settings.notchBorderOpacity = $0 / 100 }
                            ),
                            unit: "%",
                            min: 0,
                            max: 50,
                            step: 5
                        )
                    } else {
                        // Simple Mode: Sliders with larger steps
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

                            Slider(value: $settings.notchOpacity, in: 0.5...1.0, step: 0.1)
                        }

                        Divider()

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

                            Slider(value: $settings.notchBorderOpacity, in: 0.0...0.5, step: 0.1)
                        }
                    }
                }
            }

            SettingsSection(
                title: "Size",
                icon: "arrow.up.left.and.arrow.down.right",
                description: "Configure dimensions and corner radius for collapsed and expanded states"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    if settings.isAdvancedMode {
                        // Advanced Mode: Text Input Fields for all settings
                        NumberInputField(
                            title: "Corner Radius",
                            value: $settings.cornerRadius,
                            unit: "pt",
                            min: 8,
                            max: 32,
                            step: 2
                        )

                        Divider()

                        Text("Dimensions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.semibold)

                        NumberInputField(
                            title: "Collapsed Width",
                            value: $settings.collapsedWidth,
                            unit: "pt",
                            min: 200,
                            max: 400,
                            step: 10
                        )

                        NumberInputField(
                            title: "Collapsed Height",
                            value: $settings.collapsedHeight,
                            unit: "pt",
                            min: 30,
                            max: 100,
                            step: 5
                        )

                        NumberInputField(
                            title: "Expanded Width",
                            value: $settings.expandedWidth,
                            unit: "pt",
                            min: 500,
                            max: 800,
                            step: 10
                        )

                        NumberInputField(
                            title: "Expanded Height",
                            value: $settings.expandedHeight,
                            unit: "pt",
                            min: 300,
                            max: 1000,
                            step: 10
                        )
                    } else {
                        // Simple Mode: Only corner radius with larger steps
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

                            Slider(value: $settings.cornerRadius, in: 8...32, step: 5)
                        }
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

    // MARK: - Theme Actions
    private func exportTheme() {
        let theme = themeManager.exportTheme(from: settings, themeName: themeName)

        do {
            // Create save panel
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "\(theme.name.replacingOccurrences(of: " ", with: "_")).json"
            savePanel.message = "Export your theme as a JSON file"

            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    do {
                        try themeManager.saveThemeToFile(theme: theme, to: url)
                        showExportSuccess = true
                        showImportError = false

                        // Hide success message after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showExportSuccess = false
                        }
                    } catch {
                        showImportError = true
                        showExportSuccess = false
                        errorMessage = "Failed to export theme: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private func importTheme() {
        // Create open panel
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.message = "Select a theme JSON file to import"

        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                do {
                    let theme = try themeManager.importTheme(from: url)
                    themeManager.applyTheme(theme, to: settings)
                    themeName = theme.name

                    showExportSuccess = true
                    showImportError = false

                    // Hide success message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showExportSuccess = false
                    }
                } catch {
                    showImportError = true
                    showExportSuccess = false
                    errorMessage = "Failed to import theme: \(error.localizedDescription)"

                    // Hide error message after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        showImportError = false
                    }
                }
            }
        }
    }

    private func applyPresetTheme(_ theme: NotchTheme) {
        withAnimation {
            themeManager.applyTheme(theme, to: settings)
            themeName = theme.name
        }
    }

    private func getThemeColor(_ colorString: String) -> Color {
        switch colorString {
        case "black": return .black
        case "gray": return Color(white: 0.15)
        case "blue": return Color(red: 0.05, green: 0.05, blue: 0.15)
        case "purple": return Color(red: 0.1, green: 0.05, blue: 0.15)
        case "pink": return .pink
        case "green": return .green
        case "orange": return .orange
        default: return .blue
        }
    }
}

// MARK: - Modules Settings
struct ModulesSettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var moduleManager = ModuleManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Tab Description
            VStack(alignment: .leading, spacing: 4) {
                Text("Modules")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Enable or disable features and widgets in your notch")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)

            // Preview Section
            HStack {
                Spacer()
                NotchPreviewView()
                Spacer()
            }

            // New Module System
            SettingsSection(
                title: "New Modules",
                icon: "sparkles",
                description: "Modern modular widgets with enhanced functionality"
            ) {
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
            SettingsSection(
                title: "Legacy Modules",
                icon: "square.grid.2x2.fill",
                description: "Classic modules from earlier versions"
            ) {
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
        case "todolist":
            return "Manage your daily tasks with automatic cleanup of completed items"
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
            // Tab Description
            VStack(alignment: .leading, spacing: 4) {
                Text("Behavior")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Configure how your notch responds to interactions and animations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)

            SettingsSection(
                title: "Interaction",
                icon: "hand.tap.fill",
                description: "Control how the notch responds to mouse hover and clicks"
            ) {
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

            SettingsSection(
                title: "Animations",
                icon: "wand.and.stars",
                description: "Adjust animation speed and smoothness"
            ) {
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
    let description: String?
    @ViewBuilder let content: Content

    init(title: String, icon: String, description: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.description = description
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.accentColor)
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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

// MARK: - Number Input Field
struct NumberInputField: View {
    let title: String
    @Binding var value: Double
    let unit: String
    let min: Double
    let max: Double
    let step: Double

    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool

    init(title: String, value: Binding<Double>, unit: String, min: Double, max: Double, step: Double = 1) {
        self.title = title
        self._value = value
        self.unit = unit
        self.min = min
        self.max = max
        self.step = step
        self._textValue = State(initialValue: String(format: "%.0f", value.wrappedValue))
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: 4) {
                TextField("", text: $textValue)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)
                    .focused($isFocused)
                    .onChange(of: textValue) { oldValue, newValue in
                        validateAndUpdate(newValue)
                    }
                    .onChange(of: value) { oldValue, newValue in
                        if !isFocused {
                            textValue = String(format: "%.0f", newValue)
                        }
                    }
                    .onSubmit {
                        validateAndUpdate(textValue)
                        isFocused = false
                    }

                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 24, alignment: .leading)
            }
        }
    }

    private func validateAndUpdate(_ input: String) {
        // Remove any non-numeric characters except decimal point
        let filtered = input.filter { $0.isNumber || $0 == "." }

        if let number = Double(filtered) {
            // Clamp to min/max bounds
            let clamped = Swift.min(Swift.max(number, min), max)

            // Round to nearest step
            let rounded = round(clamped / step) * step

            value = rounded

            // Update text value if not focused or if value was clamped
            if !isFocused || number != rounded {
                textValue = String(format: "%.0f", rounded)
            }
        } else if filtered.isEmpty {
            // If empty, reset to minimum value
            value = min
            if !isFocused {
                textValue = String(format: "%.0f", min)
            }
        }
    }
}

#Preview {
    SettingsView()
        .frame(width: 700, height: 500)
}

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

    enum SettingsTab: CaseIterable, Identifiable {
        case appearance
        case modules

        var id: String {
            switch self {
            case .appearance: return "appearance"
            case .modules: return "modules"
            }
        }

        var title: LocalizedStringKey {
            switch self {
            case .appearance: return "settings.tab.appearance"
            case .modules: return "settings.tab.modules"
            }
        }

        var icon: String {
            switch self {
            case .appearance: return "paintbrush.fill"
            case .modules: return "square.grid.2x2.fill"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                Label(tab.title, systemImage: tab.icon)
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
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .navigationTitle("settings.window.title")
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
                Text("settings.appearance.title")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("settings.appearance.description")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)

            // Theme Management Section
            SettingsSection(
                title: "settings.theme.title",
                icon: "paintbrush.pointed.fill",
                description: "settings.theme.description"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    // Theme Name
                    HStack {
                        Text("settings.theme.name.label")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("settings.theme.name.placeholder", text: $themeName)
                            .textFieldStyle(.roundedBorder)
                    }

                    Divider()

                    // Export/Import Buttons
                    HStack(spacing: 12) {
                        Button(action: exportTheme) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("settings.theme.export.button")
                            }
                        }
                        .buttonStyle(.bordered)

                        Button(action: importTheme) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("settings.theme.import.button")
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    // Success/Error Messages
                    if showExportSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("settings.theme.export.success")
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
                    Text("settings.theme.preset.label")
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
                Text("settings.mode.label")
                    .font(.headline)
                Spacer()
                Picker("", selection: $settings.isAdvancedMode) {
                    Text("settings.mode.simple").tag(false)
                    Text("settings.mode.advanced").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding()
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)

            SettingsSection(
                title: "settings.colors.title",
                icon: "paintpalette.fill",
                description: "settings.colors.description"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    // Background Color
                    VStack(alignment: .leading, spacing: 8) {
                        Text("settings.colors.background.label")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("", selection: $settings.notchBackgroundColor) {
                            HStack {
                                Circle()
                                    .fill(.black)
                                    .frame(width: 16, height: 16)
                                Text("settings.colors.black")
                            }.tag("black")

                            HStack {
                                Circle()
                                    .fill(Color(white: 0.15))
                                    .frame(width: 16, height: 16)
                                Text("settings.colors.dark_gray")
                            }.tag("gray")

                            HStack {
                                Circle()
                                    .fill(Color(red: 0.05, green: 0.05, blue: 0.15))
                                    .frame(width: 16, height: 16)
                                Text("settings.colors.dark_blue")
                            }.tag("blue")

                            HStack {
                                Circle()
                                    .fill(Color(red: 0.1, green: 0.05, blue: 0.15))
                                    .frame(width: 16, height: 16)
                                Text("settings.colors.dark_purple")
                            }.tag("purple")
                        }
                        .pickerStyle(.radioGroup)
                    }

                    Divider()

                    // Accent Color
                    VStack(alignment: .leading, spacing: 8) {
                        Text("settings.colors.accent.label")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("", selection: $settings.accentColor) {
                            HStack {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 16, height: 16)
                                Text("settings.colors.blue")
                            }.tag("blue")

                            HStack {
                                Circle()
                                    .fill(.purple)
                                    .frame(width: 16, height: 16)
                                Text("settings.colors.purple")
                            }.tag("purple")

                            HStack {
                                Circle()
                                    .fill(.pink)
                                    .frame(width: 16, height: 16)
                                Text("settings.colors.pink")
                            }.tag("pink")

                            HStack {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 16, height: 16)
                                Text("settings.colors.green")
                            }.tag("green")

                            HStack {
                                Circle()
                                    .fill(.orange)
                                    .frame(width: 16, height: 16)
                                Text("settings.colors.orange")
                            }.tag("orange")
                        }
                        .pickerStyle(.radioGroup)
                    }
                }
            }

            SettingsSection(
                title: "settings.opacity.title",
                icon: "circle.lefthalf.filled",
                description: "settings.opacity.description"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    if settings.isAdvancedMode {
                        // Advanced Mode: Text Input Fields
                        NumberInputField(
                            title: "settings.opacity.background.label",
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
                            title: "settings.opacity.border.label",
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
                                Text("settings.opacity.background.label")
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
                                Text("settings.opacity.border.label")
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
                title: "settings.size.title",
                icon: "arrow.up.left.and.arrow.down.right",
                description: "settings.size.description"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    if settings.isAdvancedMode {
                        // Advanced Mode: Text Input Fields for all settings
                        NumberInputField(
                            title: "settings.size.corner_radius.label",
                            value: $settings.cornerRadius,
                            unit: "pt",
                            min: 8,
                            max: 32,
                            step: 2
                        )

                        Divider()

                        Text("settings.size.dimensions.label")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.semibold)

                        NumberInputField(
                            title: "settings.size.collapsed_width.label",
                            value: $settings.collapsedWidth,
                            unit: "pt",
                            min: 200,
                            max: 400,
                            step: 10
                        )

                        NumberInputField(
                            title: "settings.size.collapsed_height.label",
                            value: $settings.collapsedHeight,
                            unit: "pt",
                            min: 20,
                            max: 100,
                            step: 5
                        )

                        NumberInputField(
                            title: "settings.size.expanded_width.label",
                            value: $settings.expandedWidth,
                            unit: "pt",
                            min: 500,
                            max: 800,
                            step: 10
                        )

                        NumberInputField(
                            title: "settings.size.expanded_height.label",
                            value: $settings.expandedHeight,
                            unit: "pt",
                            min: 300,
                            max: 1000,
                            step: 10
                        )

                        Divider()

                        Text("settings.size.spacing.label")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.semibold)

                        NumberInputField(
                            title: "settings.size.collapsed_padding.label",
                            value: $settings.collapsedPadding,
                            unit: "pt",
                            min: 4,
                            max: 24,
                            step: 2
                        )
                    } else {
                        // Simple Mode: Only corner radius with larger steps
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("settings.size.corner_radius.label")
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

            SettingsSection(
                title: "settings.interaction.title",
                icon: "hand.tap.fill",
                description: "settings.interaction.description"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("settings.interaction.auto_expand.label", isOn: $settings.autoExpandOnHover)
                        .toggleStyle(.switch)

                    if settings.autoExpandOnHover {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("settings.interaction.collapse_delay.label")
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
                title: "settings.animations.title",
                icon: "wand.and.stars",
                description: "settings.animations.description"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("settings.animations.duration.label")
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

            // Reset Button
            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        settings.resetToDefaults()
                    }
                }) {
                    Text("settings.reset.button")
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
            savePanel.message = NSLocalizedString("settings.theme.export.message", comment: "Export theme dialog message")

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
                        errorMessage = String(format: NSLocalizedString("settings.theme.export.error", comment: ""), error.localizedDescription)
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
        openPanel.message = NSLocalizedString("settings.theme.import.message", comment: "Import theme dialog message")

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
                    errorMessage = String(format: NSLocalizedString("settings.theme.import.error", comment: ""), error.localizedDescription)

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
                Text("settings.modules.title")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("settings.modules.description")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)

            // Preview Section with drag & drop
            HStack {
                Spacer()
                NotchPreviewView()
                Spacer()
            }

            // Module System
            SettingsSection(
                title: "settings.modules.available.title",
                icon: "sparkles",
                description: "settings.modules.available.description"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    // Drag & Drop hint
                    HStack(spacing: 12) {
                        Image(systemName: "hand.point.up.left.and.text")
                            .font(.title3)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.modules.drag.title")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("settings.modules.drag.description")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)

                    Divider()

                    if moduleManager.availableModules.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "info.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("settings.modules.empty.title")
                                        .font(.headline)
                                    Text("settings.modules.empty.description")
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

            Spacer()
        }
        .padding(24)
    }
}

// MARK: - Dynamic Module Display
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
                HStack(spacing: 6) {
                    Text(module.name)
                        .font(.headline)

                    // Status badge
                    Text(module.isEnabled ? "settings.modules.status.enabled" : "settings.modules.status.disabled")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(module.isEnabled ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.2))
                        )
                        .foregroundColor(module.isEnabled ? .accentColor : .secondary)
                }

                Text(getModuleDescriptionKey())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private func getModuleDescriptionKey() -> LocalizedStringKey {
        // Return specific description keys for known modules
        switch module.id {
        case "calendar":
            return "module.calendar.description"
        case "todolist":
            return "module.todolist.description"
        case "mediacontroller":
            return "module.mediacontroller.description"
        case "calculator":
            return "module.calculator.description"
        case "fileManager":
            return "module.filemanager.description"
        default:
            return "module.custom.description"
        }
    }
}

// MARK: - Helper Views
struct SettingsSection<Content: View>: View {
    let title: LocalizedStringKey
    let icon: String
    let description: LocalizedStringKey?
    @ViewBuilder let content: Content

    init(title: LocalizedStringKey, icon: String, description: LocalizedStringKey? = nil, @ViewBuilder content: () -> Content) {
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
    let title: LocalizedStringKey
    @Binding var value: Double
    let unit: String
    let min: Double
    let max: Double
    let step: Double

    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool

    init(title: LocalizedStringKey, value: Binding<Double>, unit: String, min: Double, max: Double, step: Double = 1) {
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
                    .onKeyPress { keyPress in
                        if keyPress.key == .upArrow {
                            incrementValue()
                            return .handled
                        } else if keyPress.key == .downArrow {
                            decrementValue()
                            return .handled
                        }
                        return .ignored
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

    private func incrementValue() {
        let newValue = Swift.min(value + step, max)
        value = newValue
        textValue = String(format: "%.0f", newValue)
    }

    private func decrementValue() {
        let newValue = Swift.max(value - step, min)
        value = newValue
        textValue = String(format: "%.0f", newValue)
    }
}

#Preview {
    SettingsView()
        .frame(width: 700, height: 500)
}

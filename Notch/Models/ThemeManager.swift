//
//  ThemeManager.swift
//  Notch
//
//  Created by Nikita Stogniy on 11/11/25.
//

import SwiftUI
import Foundation

// MARK: - Theme Model
struct NotchTheme: Codable, Identifiable {
    var id = UUID()
    var name: String
    var notchBackgroundColor: String
    var accentColor: String
    var notchOpacity: Double
    var notchBorderOpacity: Double
    var cornerRadius: Double
    var collapsedWidth: Double
    var collapsedHeight: Double
    var expandedWidth: Double
    var expandedHeight: Double

    enum CodingKeys: String, CodingKey {
        case name
        case notchBackgroundColor
        case accentColor
        case notchOpacity
        case notchBorderOpacity
        case cornerRadius
        case collapsedWidth
        case collapsedHeight
        case expandedWidth
        case expandedHeight
    }
}

// MARK: - Theme Manager
class ThemeManager {
    static let shared = ThemeManager()

    private init() {}

    // MARK: - Preset Themes
    static let presetThemes: [NotchTheme] = [
        NotchTheme(
            name: "Classic Dark",
            notchBackgroundColor: "black",
            accentColor: "blue",
            notchOpacity: 1.0,
            notchBorderOpacity: 0.2,
            cornerRadius: 18,
            collapsedWidth: 310,
            collapsedHeight: 40,
            expandedWidth: 680,
            expandedHeight: 360
        ),
        NotchTheme(
            name: "Midnight Purple",
            notchBackgroundColor: "purple",
            accentColor: "purple",
            notchOpacity: 0.95,
            notchBorderOpacity: 0.3,
            cornerRadius: 20,
            collapsedWidth: 310,
            collapsedHeight: 40,
            expandedWidth: 680,
            expandedHeight: 360
        ),
        NotchTheme(
            name: "Ocean Blue",
            notchBackgroundColor: "blue",
            accentColor: "blue",
            notchOpacity: 0.9,
            notchBorderOpacity: 0.25,
            cornerRadius: 16,
            collapsedWidth: 300,
            collapsedHeight: 38,
            expandedWidth: 660,
            expandedHeight: 350
        ),
        NotchTheme(
            name: "Minimal",
            notchBackgroundColor: "gray",
            accentColor: "green",
            notchOpacity: 0.85,
            notchBorderOpacity: 0.15,
            cornerRadius: 24,
            collapsedWidth: 280,
            collapsedHeight: 35,
            expandedWidth: 640,
            expandedHeight: 340
        )
    ]

    // MARK: - Export Theme
    func exportTheme(from settings: SettingsManager, themeName: String) -> NotchTheme {
        return NotchTheme(
            name: themeName.isEmpty ? "My Theme" : themeName,
            notchBackgroundColor: settings.notchBackgroundColor,
            accentColor: settings.accentColor,
            notchOpacity: settings.notchOpacity,
            notchBorderOpacity: settings.notchBorderOpacity,
            cornerRadius: settings.cornerRadius,
            collapsedWidth: settings.collapsedWidth,
            collapsedHeight: settings.collapsedHeight,
            expandedWidth: settings.expandedWidth,
            expandedHeight: settings.expandedHeight
        )
    }

    func exportThemeToFile(theme: NotchTheme) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let jsonData = try encoder.encode(theme)

        // Create a temporary file
        let fileName = "\(theme.name.replacingOccurrences(of: " ", with: "_")).json"
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        try jsonData.write(to: fileURL)

        return fileURL
    }

    func saveThemeToFile(theme: NotchTheme, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let jsonData = try encoder.encode(theme)
        try jsonData.write(to: url)
    }

    // MARK: - Import Theme
    func importTheme(from url: URL) throws -> NotchTheme {
        let jsonData = try Data(contentsOf: url)
        let decoder = JSONDecoder()

        let theme = try decoder.decode(NotchTheme.self, from: jsonData)

        // Validate theme values
        try validateTheme(theme)

        return theme
    }

    func importThemeFromJSON(_ jsonString: String) throws -> NotchTheme {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw ThemeError.invalidJSON
        }

        let decoder = JSONDecoder()
        let theme = try decoder.decode(NotchTheme.self, from: jsonData)

        // Validate theme values
        try validateTheme(theme)

        return theme
    }

    // MARK: - Apply Theme
    func applyTheme(_ theme: NotchTheme, to settings: SettingsManager) {
        settings.notchBackgroundColor = theme.notchBackgroundColor
        settings.accentColor = theme.accentColor
        settings.notchOpacity = theme.notchOpacity
        settings.notchBorderOpacity = theme.notchBorderOpacity
        settings.cornerRadius = theme.cornerRadius
        settings.collapsedWidth = theme.collapsedWidth
        settings.collapsedHeight = theme.collapsedHeight
        settings.expandedWidth = theme.expandedWidth
        settings.expandedHeight = theme.expandedHeight
    }

    // MARK: - Validation
    private func validateTheme(_ theme: NotchTheme) throws {
        // Validate color strings
        let validBackgroundColors = ["black", "gray", "blue", "purple"]
        let validAccentColors = ["blue", "purple", "pink", "green", "orange"]

        guard validBackgroundColors.contains(theme.notchBackgroundColor) else {
            throw ThemeError.invalidBackgroundColor
        }

        guard validAccentColors.contains(theme.accentColor) else {
            throw ThemeError.invalidAccentColor
        }

        // Validate opacity ranges
        guard (0.5...1.0).contains(theme.notchOpacity) else {
            throw ThemeError.invalidOpacity("Background opacity must be between 50% and 100%")
        }

        guard (0.0...0.5).contains(theme.notchBorderOpacity) else {
            throw ThemeError.invalidOpacity("Border opacity must be between 0% and 50%")
        }

        // Validate size ranges
        guard (8...32).contains(theme.cornerRadius) else {
            throw ThemeError.invalidSize("Corner radius must be between 8 and 32")
        }

        guard (200...400).contains(theme.collapsedWidth) else {
            throw ThemeError.invalidSize("Collapsed width must be between 200 and 400")
        }

        guard (30...100).contains(theme.collapsedHeight) else {
            throw ThemeError.invalidSize("Collapsed height must be between 30 and 100")
        }

        guard (500...800).contains(theme.expandedWidth) else {
            throw ThemeError.invalidSize("Expanded width must be between 500 and 800")
        }

        guard (300...1000).contains(theme.expandedHeight) else {
            throw ThemeError.invalidSize("Expanded height must be between 300 and 1000")
        }
    }
}

// MARK: - Theme Errors
enum ThemeError: LocalizedError {
    case invalidJSON
    case invalidBackgroundColor
    case invalidAccentColor
    case invalidOpacity(String)
    case invalidSize(String)
    case fileNotFound
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Invalid JSON format"
        case .invalidBackgroundColor:
            return "Invalid background color. Must be one of: black, gray, blue, purple"
        case .invalidAccentColor:
            return "Invalid accent color. Must be one of: blue, purple, pink, green, orange"
        case .invalidOpacity(let message):
            return message
        case .invalidSize(let message):
            return message
        case .fileNotFound:
            return "Theme file not found"
        case .exportFailed:
            return "Failed to export theme"
        }
    }
}

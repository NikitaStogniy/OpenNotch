//
//  SettingsManager.swift
//  Notch
//
//  Created by Nikita Stogniy on 8/11/25.
//

import SwiftUI
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Appearance Settings
    @AppStorage("isAdvancedMode") var isAdvancedMode: Bool = false {
        willSet { objectWillChange.send() }
    }
    @AppStorage("notchBackgroundColor") var notchBackgroundColor: String = "black" {
        willSet { objectWillChange.send() }
    }
    @AppStorage("notchOpacity") var notchOpacity: Double = 1.0 {
        willSet { objectWillChange.send() }
    }
    @AppStorage("notchBorderOpacity") var notchBorderOpacity: Double = 0.2 {
        willSet { objectWillChange.send() }
    }
    @AppStorage("accentColor") var accentColor: String = "blue" {
        willSet { objectWillChange.send() }
    }

    // MARK: - Size Settings
    @AppStorage("collapsedWidth") var collapsedWidth: Double = 310 {
        willSet { objectWillChange.send() }
    }
    @AppStorage("collapsedHeight") var collapsedHeight: Double = 40 {
        willSet { objectWillChange.send() }
    }
    @AppStorage("expandedWidth") var expandedWidth: Double = 680 {
        willSet { objectWillChange.send() }
    }
    @AppStorage("expandedHeight") var expandedHeight: Double = 360 {
        willSet { objectWillChange.send() }
    }
    @AppStorage("cornerRadius") var cornerRadius: Double = 18 {
        willSet { objectWillChange.send() }
    }
    @AppStorage("collapsedPadding") var collapsedPadding: Double = 12 {
        willSet { objectWillChange.send() }
    }

    // MARK: - Module Settings
    @AppStorage("calculatorEnabled") var calculatorEnabled: Bool = true {
        willSet { objectWillChange.send() }
    }
    @AppStorage("fileManagerEnabled") var fileManagerEnabled: Bool = true {
        willSet { objectWillChange.send() }
    }

    // Module positioning settings
    @AppStorage("moduleOrderLeft") private var moduleOrderLeftData: Data = Data() {
        willSet { objectWillChange.send() }
    }
    @AppStorage("moduleOrderRight") private var moduleOrderRightData: Data = Data() {
        willSet { objectWillChange.send() }
    }
    @AppStorage("moduleSideAssignments") private var moduleSideAssignmentsData: Data = Data() {
        willSet { objectWillChange.send() }
    }

    var moduleOrderLeft: [String] {
        get {
            if let decoded = try? JSONDecoder().decode([String].self, from: moduleOrderLeftData) {
                return decoded
            }
            return []
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                moduleOrderLeftData = encoded
            }
        }
    }

    var moduleOrderRight: [String] {
        get {
            if let decoded = try? JSONDecoder().decode([String].self, from: moduleOrderRightData) {
                return decoded
            }
            return []
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                moduleOrderRightData = encoded
            }
        }
    }

    var moduleSideAssignments: [String: ModuleSide] {
        get {
            if let decoded = try? JSONDecoder().decode([String: ModuleSide].self, from: moduleSideAssignmentsData) {
                return decoded
            }
            return [:]
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                moduleSideAssignmentsData = encoded
            }
        }
    }

    // MARK: - Behavior Settings
    @AppStorage("autoExpandOnHover") var autoExpandOnHover: Bool = true {
        willSet { objectWillChange.send() }
    }
    @AppStorage("collapseDelay") var collapseDelay: Double = 0.25 {
        willSet { objectWillChange.send() }
    }
    @AppStorage("animationDuration") var animationDuration: Double = 0.25 {
        willSet { objectWillChange.send() }
    }

    private init() {}

    // MARK: - Helper Methods
    func resetToDefaults() {
        isAdvancedMode = false
        notchBackgroundColor = "black"
        notchOpacity = 1.0
        notchBorderOpacity = 0.2
        accentColor = "blue"

        collapsedWidth = 310
        collapsedHeight = 40
        expandedWidth = 680
        expandedHeight = 360
        cornerRadius = 18
        collapsedPadding = 12

        calculatorEnabled = true
        fileManagerEnabled = true

        autoExpandOnHover = true
        collapseDelay = 0.25
        animationDuration = 0.25
    }

    // Convert color string to Color
    func getBackgroundColor() -> Color {
        switch notchBackgroundColor {
        case "black": return .black
        case "gray": return Color(white: 0.15)
        case "blue": return Color(red: 0.05, green: 0.05, blue: 0.15)
        case "purple": return Color(red: 0.1, green: 0.05, blue: 0.15)
        default: return .black
        }
    }

    func getAccentColor() -> Color {
        switch accentColor {
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "green": return .green
        case "orange": return .orange
        default: return .blue
        }
    }
}

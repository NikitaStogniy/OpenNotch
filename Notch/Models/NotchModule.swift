//
//  NotchModule.swift
//  Notch
//
//  Created by Nikita Stogniy on 11/11/25.
//

import SwiftUI

/// Enum representing which side of the notch a module appears on
enum ModuleSide: String, Codable {
    case left
    case right
}

/// Protocol that all notch modules must conform to
protocol NotchModule: Identifiable {
    /// Unique identifier for the module
    var id: String { get }

    /// Display name of the module
    var name: String { get }

    /// Icon for the module (SF Symbol name)
    var icon: String { get }

    /// Mini icon for collapsed state (SF Symbol name, 20x20pt)
    var miniIcon: String { get }

    /// Preferred side for the module in collapsed state
    var side: ModuleSide { get }

    /// Whether the module is currently enabled
    var isEnabled: Bool { get set }

    /// View for collapsed state (optional)
    @ViewBuilder func collapsedView() -> AnyView

    /// View for expanded state
    @ViewBuilder func expandedView() -> AnyView

    /// Whether this module should show in collapsed state
    var showInCollapsed: Bool { get }

    /// Priority for display order (higher = shown first)
    var priority: Int { get }
}

extension NotchModule {
    /// Default implementation returns empty view
    func collapsedView() -> AnyView {
        AnyView(EmptyView())
    }

    /// Default: don't show in collapsed state
    var showInCollapsed: Bool {
        false
    }

    /// Default priority
    var priority: Int {
        0
    }

    /// Default: use same icon as main icon
    var miniIcon: String {
        icon
    }

    /// Default: appear on left side
    var side: ModuleSide {
        .left
    }
}

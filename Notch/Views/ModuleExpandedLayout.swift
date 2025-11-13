//
//  ModuleExpandedLayout.swift
//  Notch
//
//  Standardized layout for all expanded module views
//

import SwiftUI

/// Standardized layout wrapper for expanded module views
/// Provides consistent spacing, header, and divider across all modules
struct ModuleExpandedLayout<Content: View, HeaderAction: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let headerAction: HeaderAction
    @ViewBuilder let content: Content

    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(settings.getAccentColor())
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    headerAction
                }
                .padding(.bottom, 16)

                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.bottom, 16)

                // Content - gets exact remaining height
                let contentHeight = geometry.size.height - 24 - 16 - 1 - 16 - 32

                ZStack {
                    Color.clear
                    content
                }
                .frame(width: geometry.size.width - 32, height: contentHeight)
            }
            .padding(16)
        }
    }
}

// Convenience initializer for layouts without header actions
extension ModuleExpandedLayout where HeaderAction == EmptyView {
    init(icon: String, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.headerAction = EmptyView()
        self.content = content()
    }
}

#Preview {
    ModuleExpandedLayout(icon: "checklist", title: "To-Do List") {
        Text("Sample content")
            .foregroundColor(.white)
    }
    .frame(width: 300, height: 400)
    .background(.black)
}

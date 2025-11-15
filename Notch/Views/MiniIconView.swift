//
//  MiniIconView.swift
//  Notch
//
//  Created for OpenNotch
//

import SwiftUI

/// A mini icon view for displaying modules in collapsed state
struct MiniIconView: View {
    let module: any NotchModule
    let onTap: () -> Void

    @State private var isHovering = false
    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        ZStack {
            Image(systemName: module.miniIcon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .scaleEffect(isHovering ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
        }
        .frame(width: 28, height: 28)
        .background(
            Circle()
                .fill(isHovering ? settings.getAccentColor().opacity(0.3) : Color.clear)
                .animation(.easeInOut(duration: 0.2), value: isHovering)
        )
        .contentShape(Circle())
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            onTap()
        }
        .help(module.name) // Tooltip on hover
    }
}

/// Preview provider for MiniIconView
#Preview {
    HStack(spacing: 12) {
        MiniIconView(module: CalendarModule()) { }
        MiniIconView(module: TodoListModule()) { }
        MiniIconView(module: MediaControllerModule()) { }
    }
    .padding()
    .background(Color.black)
}

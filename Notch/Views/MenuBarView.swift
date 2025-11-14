//
//  MenuBarView.swift
//  Notch
//
//  Created by Nikita Stogniy on 7/11/25.
//

import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openSettings) private var openSettings
    @Query private var storedFiles: [StoredFile]
    @StateObject private var windowManager = FloatingWindowManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "music.note.list")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("app.name")
                    .font(.headline)
                Spacer()
            }
            .padding()

            Divider()

            // Toggle Notch Visibility
            Button(action: {
                windowManager.toggle()
            }) {
                HStack {
                    Image(systemName: windowManager.isVisible ? "eye.slash" : "eye")
                    Text(windowManager.isVisible ? "menu.notch.hide" : "menu.notch.show")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Recent Files Section
            if !storedFiles.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: NSLocalizedString("menu.recent_files.title", comment: ""), storedFiles.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    ScrollView {
                        ForEach(storedFiles) { file in
                            MenuBarFileRow(file: file)
                        }
                    }
                    .frame(maxHeight: 300)
                }

                Divider()
            }

            // Quick Actions
            VStack(spacing: 0) {
                MenuBarButton(icon: "gearshape", title: NSLocalizedString("menu.settings", comment: "")) {
                    showSettings()
                }

                MenuBarButton(icon: "info.circle", title: NSLocalizedString("menu.about", comment: "")) {
                    showAbout()
                }
            }

            Divider()

            // Quit Button
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                        .foregroundColor(.red)
                    Text("menu.quit")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(width: 300)
    }

    // MARK: - Actions
    private func showSettings() {
        openSettings()
    }

    private func showAbout() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("about.title", comment: "")
        let subtitle = NSLocalizedString("about.subtitle", comment: "")
        let version = String(format: NSLocalizedString("about.version", comment: ""), "1.0.0")
        let description = NSLocalizedString("about.description", comment: "")
        let credits = NSLocalizedString("about.credits", comment: "")
        let copyright = NSLocalizedString("about.copyright", comment: "")

        alert.informativeText = """
        \(subtitle)

        \(version)

        \(description)

        \(credits)
        \(copyright)
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: NSLocalizedString("button.ok", comment: ""))
        alert.runModal()
    }
}

// MARK: - Menu Bar File Row
struct MenuBarFileRow: View {
    let file: StoredFile

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: file.fileIcon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.caption)
                    .lineLimit(1)

                Text(file.formattedFileSize)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                // Open file
                NSWorkspace.shared.open(file.fileURL)
            }) {
                Image(systemName: "arrow.up.forward.square")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Menu Bar Button
struct MenuBarButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(isHovering ? Color.blue.opacity(0.1) : Color.clear)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    MenuBarView()
        .modelContainer(for: StoredFile.self, inMemory: true)
}

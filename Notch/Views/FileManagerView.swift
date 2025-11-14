//
//  FileManagerView.swift
//  Notch
//
//  File manager view for drag & drop and file storage
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Notification Names
extension Notification.Name {
    static let draggingFromNotch = Notification.Name("draggingFromNotch")
    static let draggingFromNotchEnded = Notification.Name("draggingFromNotchEnded")
}

struct FileManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var storedFiles: [StoredFile]
    @Binding var isDropTargeted: Bool
    @State private var isDraggingFromNotch = false

    var body: some View {
        ModuleExpandedLayout(icon: "folder", title: NSLocalizedString("module.filemanager.name", comment: "")) {
            if storedFiles.isEmpty {
                dropZoneView
            } else {
                fileListView
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .draggingFromNotch)) { _ in
            isDraggingFromNotch = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .draggingFromNotchEnded)) { _ in
            isDraggingFromNotch = false
        }
    }

    private var dropZoneView: some View {
        VStack(spacing: 2) {
            Image(systemName: isDropTargeted ? "folder.badge.plus.fill" : "folder.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(isDropTargeted ? .blue : .white.opacity(0.5))
                .symbolEffect(.bounce, value: isDropTargeted)
            Text(isDropTargeted ? NSLocalizedString("filemanager.drop.release", comment: "") : NSLocalizedString("filemanager.drop.prompt", comment: ""))
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isDropTargeted ? .blue.opacity(0.2) : .white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: isDropTargeted ? [] : [5]))
                .foregroundColor(isDropTargeted ? .blue : .white.opacity(0.3))
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDropTargeted)
        .onDrop(of: [.fileURL], delegate: FileDropDelegate(modelContext: modelContext, isTargeted: $isDropTargeted, isDraggingFromNotch: isDraggingFromNotch))
    }

    private var fileListView: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(storedFiles) { file in
                    FileRowView(file: file, modelContext: modelContext)
                }
            }
        }
        .onDrop(of: [.fileURL], delegate: FileDropDelegate(modelContext: modelContext, isTargeted: $isDropTargeted, isDraggingFromNotch: isDraggingFromNotch))
    }
}

// MARK: - File Row Component
struct FileRowView: View {
    let file: StoredFile
    let modelContext: ModelContext
    @State private var isHovering = false
    @State private var isDragging = false
    @State private var isDraggingFromNotch = false

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: file.fileIcon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(.blue.opacity(0.2))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(file.formattedFileSize)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    modelContext.delete(file)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(2)
        .background(isDragging ? .blue.opacity(0.2) : (isHovering ? .white.opacity(0.1) : .white.opacity(0.05)))
        .cornerRadius(8)
        .scaleEffect(isDragging ? 0.95 : (isHovering ? 1.02 : 1.0))
        .opacity(isDragging ? 0.6 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .onHover { hovering in
            isHovering = hovering
        }
        .onDrag {
            isDragging = true
            isDraggingFromNotch = true

            // Notify that we're dragging from notch
            NotificationCenter.default.post(name: .draggingFromNotch, object: nil)

            // Reset state after drag
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isDragging = false
                isDraggingFromNotch = false
                NotificationCenter.default.post(name: .draggingFromNotchEnded, object: nil)
            }

            // Start accessing security-scoped resource
            _ = file.fileURL.startAccessingSecurityScopedResource()

            // Stop accessing after a delay (enough time for drag to complete)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                file.fileURL.stopAccessingSecurityScopedResource()
            }

            // Return NSItemProvider with file URL
            return NSItemProvider(contentsOf: file.fileURL) ?? NSItemProvider()
        }
    }
}

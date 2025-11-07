//
//  FileDropDelegate.swift
//  Notch
//
//  Created by Nikita Stogniy on 7/11/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct FileDropDelegate: DropDelegate {
    let modelContext: ModelContext
    @Binding var isTargeted: Bool
    var isDraggingFromNotch: Bool = false

    func validateDrop(info: DropInfo) -> Bool {
        // Don't accept drops if we're dragging from notch itself
        if isDraggingFromNotch {
            return false
        }
        return info.hasItemsConforming(to: [.fileURL])
    }

    func dropEntered(info: DropInfo) {
        // Don't show drop indication if dragging from notch
        if isDraggingFromNotch {
            return
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isTargeted = true
        }
    }

    func dropExited(info: DropInfo) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isTargeted = false
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        isTargeted = false

        // Don't accept drops from notch itself
        if isDraggingFromNotch {
            return false
        }

        guard info.hasItemsConforming(to: [.fileURL]) else {
            return false
        }

        let items = info.itemProviders(for: [.fileURL])

        for item in items {
            item.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (urlData, error) in
                DispatchQueue.main.async {
                    if let urlData = urlData as? Data,
                       let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                        addFile(from: url)
                    }
                }
            }
        }

        return true
    }

    private func addFile(from url: URL) {
        do {
            // Start accessing security-scoped resource
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            // Get file attributes
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            let fileName = url.lastPathComponent
            let fileExtension = url.pathExtension

            // Create StoredFile
            let storedFile = StoredFile(
                name: fileName,
                fileURL: url,
                fileType: fileExtension,
                fileSize: fileSize
            )

            modelContext.insert(storedFile)
            try modelContext.save()

        } catch {
            print("Error adding file: \(error)")
        }
    }
}

// MARK: - FileDropExpandDelegate
// Delegate that expands notch when file is dragged over it

struct FileDropExpandDelegate: DropDelegate {
    let modelContext: ModelContext
    @Binding var isTargeted: Bool
    @Binding var isDraggingFile: Bool
    @Binding var notchState: NotchState
    @Binding var isDraggingFromNotch: Bool

    func validateDrop(info: DropInfo) -> Bool {
        // Always allow validation - just expand notch
        // The actual drop will be handled by FileDropDelegate inside FileManagerView
        return info.hasItemsConforming(to: [.fileURL])
    }

    func dropEntered(info: DropInfo) {
        // Always expand notch when file is dragged over
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isDraggingFile = true
            notchState = .expanded

            // Only show target indication if not dragging from notch
            if !isDraggingFromNotch {
                isTargeted = true
            }
        }
    }

    func dropExited(info: DropInfo) {
        // Always reset states on exit
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isDraggingFile = false
            isTargeted = false
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        isDraggingFile = false
        isTargeted = false

        // Don't handle drop here - let FileManagerView handle it
        // Just return false so the drop propagates to inner views
        return false
    }
}

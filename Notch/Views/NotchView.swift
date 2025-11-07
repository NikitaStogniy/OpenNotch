//
//  NotchView.swift
//  Notch
//
//  Created by Nikita Stogniy on 7/11/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum NotchState {
    case collapsed
    case expanded
}

struct NotchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var storedFiles: [StoredFile]

    @State private var notchState: NotchState = .collapsed {
        didSet {
            updateWindowSize()
        }
    }
    @State private var isHovering = false
    @State private var isDropTargeted = false
    @State private var hoverCollapseTask: Task<Void, Never>?
    @State private var isDraggingFile = false
    @State private var isDraggingFromNotch = false

    var body: some View {
        notchContainer
            .background(.clear)
            .padding(30)
            .onHover { hovering in
                hoverCollapseTask?.cancel()

                if hovering {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isHovering = true
                        notchState = .expanded
                    }
                } else {
                    hoverCollapseTask = Task {
                        try? await Task.sleep(nanoseconds: 250_000_000)
                        guard !Task.isCancelled else { return }

                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isHovering = false
                            if !isDraggingFile {
                                notchState = .collapsed
                            }
                        }
                    }
                }
            }
            .onDrop(of: [.fileURL], delegate: FileDropExpandDelegate(
                modelContext: modelContext,
                isTargeted: $isDropTargeted,
                isDraggingFile: $isDraggingFile,
                notchState: $notchState,
                isDraggingFromNotch: $isDraggingFromNotch
            ))
            .padding(-30)
            .onReceive(NotificationCenter.default.publisher(for: .draggingFromNotch)) { _ in
                isDraggingFromNotch = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .draggingFromNotchEnded)) { _ in
                isDraggingFromNotch = false
            }
    }

    private func updateWindowSize() {
        let size = notchState.windowSize
        FloatingWindowManager.shared.updateSize(width: size.width, height: size.height, animated: true, resetPosition: true)
    }

    @ViewBuilder
    private var notchContainer: some View {
        ZStack {
            // Black background
            RoundedRectangle(cornerRadius: notchState == .collapsed ? 18 : 30)
                .fill(Color.black)
                .overlay {
                    RoundedRectangle(cornerRadius: notchState == .collapsed ? 18 : 30)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: notchState == .collapsed ? 0.5 : 1
                        )
                }
                .shadow(color: .black.opacity(notchState == .collapsed ? 0.3 : 0.5),
                       radius: notchState == .collapsed ? 10 : 20,
                       x: 0,
                       y: notchState == .collapsed ? 5 : 10)

            // Content
            VStack(spacing: 0) {
                if notchState == .collapsed {
                    collapsedContent
                } else {
                    expandedContent
                }
            }
            .padding()
        }
        .frame(
            width: notchState == .collapsed ? 200 : 680,
            height: notchState == .collapsed ? 32 : 200
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: notchState)
    }

    // MARK: - Collapsed State
    private var collapsedContent: some View {
        HStack(spacing: 12) {
            Spacer()

            // File count indicator on right
            HStack(spacing: 4) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 12))
                Text("\(storedFiles.count)")
                    .font(.system(size: 12, weight: .semibold))
            }
            .opacity(0.8)
        }
        .foregroundColor(.white)
    }

    // MARK: - Expanded State
    private var expandedContent: some View {
        FileManagerView(isDropTargeted: $isDropTargeted)
    }
}

#Preview {
    NotchView()
        .modelContainer(for: StoredFile.self, inMemory: true)
        .frame(width: 800, height: 600)
        .background(.black)
}

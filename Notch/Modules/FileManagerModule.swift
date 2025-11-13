//
//  FileManagerModule.swift
//  Notch
//
//  Created for OpenNotch
//

import SwiftUI
import SwiftData

class FileManagerModule: NotchModule {
    let id = "fileManager"
    let name = "Files"
    let icon = "folder"
    let miniIcon = "doc.fill"
    let side: ModuleSide = .right
    let priority: Int = 40

    @AppStorage("fileManagerEnabled") var isEnabled: Bool = true
    let showInCollapsed: Bool = true

    func collapsedView() -> AnyView {
        AnyView(EmptyView())
    }

    func expandedView() -> AnyView {
        AnyView(FileManagerModuleView())
    }
}

// Wrapper view that manages file manager state
struct FileManagerModuleView: View {
    @State private var isDropTargeted: Bool = false

    var body: some View {
        FileManagerView(isDropTargeted: $isDropTargeted)
    }
}

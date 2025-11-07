//
//  StoredFile.swift
//  Notch
//
//  Created by Nikita Stogniy on 7/11/25.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

@Model
final class StoredFile {
    var id: UUID
    var name: String
    var fileURL: URL
    var dateAdded: Date
    var fileType: String
    var fileSize: Int64
    var thumbnailData: Data?

    init(name: String, fileURL: URL, fileType: String, fileSize: Int64, thumbnailData: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.fileURL = fileURL
        self.dateAdded = Date()
        self.fileType = fileType
        self.fileSize = fileSize
        self.thumbnailData = thumbnailData
    }

    var fileIcon: String {
        switch fileType.lowercased() {
        case "pdf":
            return "doc.fill"
        case "jpg", "jpeg", "png", "gif", "heic":
            return "photo.fill"
        case "mp4", "mov", "avi":
            return "video.fill"
        case "mp3", "wav", "m4a":
            return "music.note"
        case "zip", "rar":
            return "archivebox.fill"
        default:
            return "doc.fill"
        }
    }

    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

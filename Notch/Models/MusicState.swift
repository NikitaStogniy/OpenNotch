//
//  MusicState.swift
//  Notch
//
//  Created by Nikita Stogniy on 7/11/25.
//

import Foundation
import SwiftUI

@Observable
class MusicState {
    var isPlaying: Bool = false
    var currentTrack: String = "No Track Playing"
    var currentArtist: String = "Unknown Artist"
    var progress: Double = 0.0
    var duration: Double = 100.0
    var volume: Double = 0.5

    func togglePlayPause() {
        isPlaying.toggle()
    }

    func nextTrack() {
        // Integration with Music app will be added later
        currentTrack = "Next Track"
    }

    func previousTrack() {
        // Integration with Music app will be added later
        currentTrack = "Previous Track"
    }

    func seek(to position: Double) {
        progress = position
    }

    var formattedProgress: String {
        let minutes = Int(progress) / 60
        let seconds = Int(progress) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

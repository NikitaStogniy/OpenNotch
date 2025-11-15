//
//  MediaControllerModule.swift
//  Notch
//
//  Created for OpenNotch
//

import SwiftUI
import MediaPlayer
import Combine

class MediaControllerModule: NotchModule, ObservableObject {
    let id = "mediacontroller"
    var name: String {
        NSLocalizedString("module.mediacontroller.name", comment: "")
    }
    let icon = "music.note"
    let miniIcon = "music.note"
    let side: ModuleSide = .right
    var priority: Int = 95
    var showInCollapsed: Bool { isPlaying }

    @AppStorage("mediaControllerEnabled") var isEnabled: Bool = true
    @Published var isPlaying: Bool = false {
        didSet {
            if isPlaying != oldValue {
                // Notify ModuleManager to refresh
                DispatchQueue.main.async {
                    ModuleManager.shared.objectWillChange.send()
                }
            }
        }
    }
    @Published var songTitle: String = ""
    @Published var artistName: String = ""
    @Published var albumArt: NSImage?
    @Published var playbackRate: Float = 0.0

    private var updateTimer: Timer?

    init() {
        setupMediaMonitoring()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    private func setupMediaMonitoring() {
        // Register for now playing info updates
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(updateNowPlayingInfo),
            name: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil
        )
    }

    private func startMonitoring() {
        // Poll for updates every 1 second
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
        updateNowPlayingInfo()
    }

    private func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
        DistributedNotificationCenter.default().removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func updateNowPlayingInfo() {
        // Check multiple music apps via AppleScript
        self.updateFromAppleScript()
    }

    private func updateFromAppleScript() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            var foundMedia = false
            var trackTitle = ""
            var trackArtist = ""
            var artworkData: Data?

            // Try Apple Music first
            if !foundMedia {
                let musicScript = """
                if application "Music" is running then
                    try
                        tell application "Music"
                            set playerState to player state
                            if playerState is playing then
                                set trackName to name of current track
                                set trackArtist to artist of current track
                                return trackName & "|||" & trackArtist
                            else
                                return "not_playing"
                            end if
                        end tell
                    on error errMsg
                        return "error: " & errMsg
                    end try
                else
                    return "not_running"
                end if
                """

                var error: NSDictionary?
                if let scriptObject = NSAppleScript(source: musicScript) {
                    let output = scriptObject.executeAndReturnError(&error)
                    if let result = output.stringValue {
                        if !result.isEmpty && result != "not_running" && result != "not_playing" && !result.starts(with: "error:") {
                            let components = result.components(separatedBy: "|||")
                            if components.count >= 2 {
                                trackTitle = components[0]
                                trackArtist = components[1]
                                foundMedia = true

                                // Try to get artwork
                                artworkData = self.getArtworkFromMusic()
                            }
                        }
                    }
                }
            }

            // Try Spotify
            if !foundMedia {
                let spotifyScript = """
                if application "Spotify" is running then
                    try
                        tell application "Spotify"
                            set playerState to player state
                            if playerState is playing then
                                set trackName to name of current track
                                set trackArtist to artist of current track
                                return trackName & "|||" & trackArtist
                            else
                                return "not_playing"
                            end if
                        end tell
                    on error errMsg
                        return "error: " & errMsg
                    end try
                else
                    return "not_running"
                end if
                """

                var error: NSDictionary?
                if let scriptObject = NSAppleScript(source: spotifyScript) {
                    let output = scriptObject.executeAndReturnError(&error)
                    if let result = output.stringValue {
                        if !result.isEmpty && result != "not_running" && result != "not_playing" && !result.starts(with: "error:") {
                            let components = result.components(separatedBy: "|||")
                            if components.count >= 2 {
                                trackTitle = components[0]
                                trackArtist = components[1]
                                foundMedia = true

                                // Try to get artwork
                                artworkData = self.getArtworkFromSpotify()
                            }
                        }
                    }
                }
            }

            // Update UI on main thread
            DispatchQueue.main.async {
                if foundMedia {
                    self.isPlaying = true
                    self.playbackRate = 1.0
                    self.songTitle = trackTitle
                    self.artistName = trackArtist

                    if let data = artworkData, let image = NSImage(data: data) {
                        self.albumArt = image
                    }
                } else {
                    self.isPlaying = false
                    self.playbackRate = 0.0
                }
            }
        }
    }

    private func getArtworkFromMusic() -> Data? {
        let script = """
        if application "Music" is running then
            tell application "Music"
                if player state is playing then
                    try
                        set artworkData to raw data of artwork 1 of current track
                        return artworkData
                    end try
                end if
            end tell
        end if
        return ""
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)
            if error == nil {
                return output.data
            }
        }
        return nil
    }

    private func getArtworkFromSpotify() -> Data? {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                if player state is playing then
                    try
                        set artworkURL to artwork url of current track
                        return artworkURL
                    end try
                end if
            end tell
        end if
        return ""
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)
            if error == nil, let urlString = output.stringValue, !urlString.isEmpty {
                // Download artwork from URL
                if let url = URL(string: urlString), let data = try? Data(contentsOf: url) {
                    return data
                }
            }
        }
        return nil
    }

    func collapsedView() -> AnyView {
        AnyView(MediaCollapsedView())
    }

    func expandedView() -> AnyView {
        AnyView(MediaExpandedView(module: self))
    }

    // Media control functions
    func playPause() {
        let script = """
        if application "Music" is running then
            tell application "Music"
                playpause
            end tell
        end if
        if application "Spotify" is running then
            tell application "Spotify"
                playpause
            end tell
        end if
        """
        executeAppleScript(script)
    }

    func nextTrack() {
        let script = """
        if application "Music" is running then
            tell application "Music"
                next track
            end tell
        end if
        if application "Spotify" is running then
            tell application "Spotify"
                next track
            end tell
        end if
        """
        executeAppleScript(script)
    }

    func previousTrack() {
        let script = """
        if application "Music" is running then
            tell application "Music"
                previous track
            end tell
        end if
        if application "Spotify" is running then
            tell application "Spotify"
                previous track
            end tell
        end if
        """
        executeAppleScript(script)
    }

    private func executeAppleScript(_ script: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: script) {
                scriptObject.executeAndReturnError(&error)
            }
        }
    }
}

// MARK: - Collapsed View (Animated Equalizer Icon)
struct MediaCollapsedView: View {
    @State private var barHeights: [CGFloat] = [0.3, 0.6, 0.4]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 3, height: 12 * barHeights[index])
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: barHeights[index]
                    )
            }
        }
        .frame(width: 15, height: 12)
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Animate the bars
        withAnimation {
            barHeights = [0.8, 0.4, 0.9]
        }
    }
}

// MARK: - Expanded View (Full Media Controls)
struct MediaExpandedView: View {
    @ObservedObject var module: MediaControllerModule
    @StateObject private var settings = SettingsManager.shared
    @State private var isHoveringCover = false

    var body: some View {
        ModuleExpandedLayout(icon: "music.note", title: NSLocalizedString("module.mediacontroller.name", comment: "")) {
            VStack(spacing: 16) {
                // Song info
                VStack(spacing: 4) {
                    Text(module.songTitle.isEmpty ? NSLocalizedString("media.empty.message", comment: "") : module.songTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if !module.artistName.isEmpty {
                        Text(module.artistName)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }

                // Album art with play/pause overlay
                ZStack {
                    if let albumArt = module.albumArt {
                        Image(nsImage: albumArt)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.3))
                            )
                    }

                    // Play/Pause overlay on hover
                    if isHoveringCover {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Button(action: {
                                    module.playPause()
                                }) {
                                    Image(systemName: module.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(PlainButtonStyle())
                            )
                    }
                }
                .frame(width: 120, height: 120)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHoveringCover = hovering
                    }
                }

                // Control buttons
                HStack(spacing: 24) {
                    // Previous button
                    Button(action: {
                        module.previousTrack()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle())

                    // Play/Pause button (always visible)
                    Button(action: {
                        module.playPause()
                    }) {
                        Image(systemName: module.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle())

                    // Next button
                    Button(action: {
                        module.nextTrack()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle())
                }
                .padding(.top, 8)
            }
        }
    }
}

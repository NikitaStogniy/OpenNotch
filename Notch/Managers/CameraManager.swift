//
//  CameraManager.swift
//  Notch
//
//  Camera manager for handling camera access and preview
//

import AVFoundation
import AppKit

@Observable
class CameraManager: NSObject {
    var isAuthorized: Bool = false
    var isSessionRunning: Bool = false
    var previewLayer: AVCaptureVideoPreviewLayer?
    var errorMessage: String?

    private var captureSession: AVCaptureSession?
    private let sessionQueue = DispatchQueue(label: "com.notch.camera.session")

    override init() {
        super.init()
        checkAuthorization()
    }

    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            requestAccess()
        case .denied:
            isAuthorized = false
            errorMessage = "Camera access denied"
        case .restricted:
            isAuthorized = false
            errorMessage = "Camera access restricted"
        @unknown default:
            isAuthorized = false
            errorMessage = "Unknown camera status"
        }
    }

    private func requestAccess() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if !granted {
                    self?.errorMessage = "Camera access denied"
                }
            }
        }
    }

    func startSession() {
        guard isAuthorized else {
            checkAuthorization()
            return
        }

        guard captureSession == nil else {
            return
        }

        sessionQueue.async { [weak self] in
            self?.setupCaptureSession()
        }
    }

    private func setupCaptureSession() {
        guard captureSession == nil else { return }

        let session = AVCaptureSession()
        session.beginConfiguration()

        // Find the front camera
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Front camera not found"
            }
            session.commitConfiguration()
            return
        }

        // Add video input
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "Cannot add video input"
                }
                session.commitConfiguration()
                return
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Error: \(error.localizedDescription)"
            }
            session.commitConfiguration()
            return
        }

        session.sessionPreset = .medium
        session.commitConfiguration()

        // Create preview layer
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill

        DispatchQueue.main.async { [weak self] in
            self?.previewLayer = preview
            self?.captureSession = session
            self?.errorMessage = nil
        }

        // Start session
        session.startRunning()

        DispatchQueue.main.async { [weak self] in
            self?.isSessionRunning = session.isRunning
        }
    }

    func stopSession() {
        guard let session = captureSession else { return }

        sessionQueue.async { [weak self] in
            session.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }

    deinit {
        stopSession()
    }
}

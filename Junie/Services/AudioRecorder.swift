import Foundation
import AVFoundation
import AVFAudio
import SwiftUI

class AudioRecorder: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var hasPermission: Bool = false
    @Published var isUploading: Bool = false
    @Published var uploadError: String? = nil

    private var audioSession: AVAudioSession?
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    
    private let apiMiddleware: APIMiddleware

    init(apiMiddleware: APIMiddleware) {
        self.apiMiddleware = apiMiddleware
        checkMicrophonePermission()
    }

    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        audioSession = AVAudioSession.sharedInstance()
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.hasPermission = granted
                
                guard granted else {
                    print("Microphone permission denied.")
                    completion(granted)
                    return
                }

                print("Microphone permission granted.")
                // Setup audio session immediately after permission is granted
                self.setupAudioSession(activate: true)
                completion(granted)
            }
        }
    }

    private func setupAudioSession(activate: Bool = true) {
        guard hasPermission else {
            print("Cannot setup audio session: No permission.")
            return
        }
        
        if audioSession == nil {
            audioSession = AVAudioSession.sharedInstance()
        }

        guard let session = audioSession else {
            print("Audio session instance is nil.")
            return
        }

        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            print("Audio session category and mode set.")
            if activate {
                try session.setActive(true)
                print("Audio session activated.")
            }
        } catch {
            print("Failed to set up or activate audio session: \(error.localizedDescription)")
        }
    }

    private func getDocumentsDirectory() -> URL {
        // Standard way to get the app's documents directory.
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    private func newRecordingURL() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss" // ISO-like format for filenames
        let dateString = formatter.string(from: Date())
        let fileName = "recording-\(dateString).m4a" // Using .m4a for AAC audio
        return getDocumentsDirectory().appendingPathComponent(fileName)
    }

    func startRecording() {
        guard hasPermission else {
            print("Cannot start recording: Microphone permission not granted.")
            // Optionally, trigger UI to ask for permission again or guide to settings
            return
        }

        guard !isRecording else {
            print("Already recording. Ignoring startRecording request.")
            return
        }
        
        // Ensure audio session is correctly configured and active before recording
        do {
            if audioSession == nil { audioSession = AVAudioSession.sharedInstance() }
            guard let session = audioSession else {
                print("Audio session instance missing, cannot start recording.")
                return
            }
            // Ensure correct category and mode, then activate.
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            print("Audio session configured and activated for recording.")
        } catch {
            print("Failed to configure or activate audio session for recording: \(error.localizedDescription)")
            // No state change for isRecording here, as we haven't started yet.
            // Consider if UI should reflect this specific failure.
            return
        }

        recordingURL = newRecordingURL()
        guard let url = recordingURL else {
            print("Failed to create recording URL.")
            // No state change for isRecording needed here.
            return
        }
        print("Recording to: \(url.path)")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),    // MPEG-4 AAC audio format
            AVSampleRateKey: 44100,                     // Standard sample rate (CD quality)
            AVNumberOfChannelsKey: 1,                   // Mono recording
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue // High quality encoding
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)

            guard let audioRecorder = audioRecorder else {
                print("AudioRecorder: Error - Audio recorder was nil after initialization.")
                return
            }

            audioRecorder.prepareToRecord()

            guard audioRecorder.record() else {
                print("Failed to start recording: AVAudioRecorder.record() returned false.")
                return
            }
            
            DispatchQueue.main.async {
                self.isRecording = true
            }
            print("Recording started successfully.")
        } catch {
            print("Failed to initialize or start AVAudioRecorder: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        guard let recorder = audioRecorder, isRecording else {
            // If isRecording is true but recorder is nil, or vice-versa, it indicates a state inconsistency.
            print("Warning: isRecording is true, but audioRecorder is nil. Resetting state.")
            DispatchQueue.main.async { 
                self.isRecording = false
                self.audioRecorder = nil
            } // Reset UI state
            return
        }

        recorder.stop()
        // The isRecording state is set to false immediately for UI responsiveness.
        // Actual file finalization happens on the recorder's thread.
        DispatchQueue.main.async {
            self.isRecording = false
        }
        print("Recording stopped.")

        guard let url = self.recordingURL else {
            print("AudioRecorder: Error - Recording URL was nil after stopping.")
            return
        }

        print("AudioRecorder: Recording saved to \(url.path). Preparing to upload.")
        self.isUploading = true
        self.uploadError = nil

        apiMiddleware.uploadAudio(fileURL: url) { [weak self] result in
            // Ensure UI updates are on the main thread
            DispatchQueue.main.async {
                switch result {
                case .success():
                    print("AudioRecorder: Audio uploaded successfully via APIMiddleware.")
                    // Delete the local file after successful upload
                    self?.deleteRecording(at: url)
                case .failure(let error):
                    print("AudioRecorder: Failed to upload audio via APIMiddleware. Error: \(error.localizedDescription)")
                }
                self?.isUploading = false
            }
        }
        self.recordingURL = nil

        // Deactivate the audio session after recording stops
        do {
            try audioSession?.setActive(false, options: .notifyOthersOnDeactivation)
            print("Audio session deactivated.")
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }

    // Helper function to delete local recording after successful upload
    private func deleteRecording(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            print("AudioRecorder: Successfully deleted local recording at \(url.path)")
        } catch {
            print("AudioRecorder: Error deleting local recording at \(url.path): \(error.localizedDescription)")
        }
    }

    func checkMicrophonePermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            DispatchQueue.main.async {
                self.hasPermission = true
            }
            print("Microphone permission already granted.")
            // Setup session (without activating yet) if permission was pre-granted,
            // so category/mode are ready. Activation will happen before recording starts.
            setupAudioSession(activate: false)
        case .denied:
            DispatchQueue.main.async {
                self.hasPermission = false
            }
            print("Microphone permission previously denied. User must change it in Settings.")
        case .undetermined:
            DispatchQueue.main.async {
                self.hasPermission = false
            }
            print("Microphone permission undetermined. UI should prompt for request.")
        @unknown default:
            DispatchQueue.main.async {
                self.hasPermission = false
            }
            print("Unknown microphone permission status.")
        }
    }
} 

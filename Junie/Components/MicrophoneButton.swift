//
//  MicrophoneButton.swift
//  Junie
//
//  Created by Ahmed Elsaeed on 24/05/2025.
//

import SwiftUI

/// A reusable microphone button component that handles recording state and user interactions.
struct MicrophoneButton: View {
    // MARK: - Properties
    @ObservedObject var audioRecorder: AudioRecorder
    
    // MARK: - Body
    var body: some View {
        Button(action: {}) {
            Image(systemName: "mic.fill")
                .font(.system(size: 60))
                .foregroundColor(buttonColor)
                .padding(20)
                .background(Circle().fill(backgroundColor))
                .shadow(radius: audioRecorder.isRecording ? 10 : 5)
        }
        .disabled(!audioRecorder.hasPermission)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    handleRecordingStart()
                }
                .onEnded { _ in
                    handleRecordingStop()
                }
        )
    }
    
    // MARK: - Private Methods
    private func handleRecordingStart() {
        guard audioRecorder.hasPermission, !audioRecorder.isRecording else { return }
        audioRecorder.startRecording()
    }
    
    private func handleRecordingStop() {
        guard audioRecorder.isRecording else { return }
        audioRecorder.stopRecording()
    }
    
    // MARK: - Private Properties
    private var buttonColor: Color {
        if !audioRecorder.hasPermission {
            return .gray
        }
        return audioRecorder.isRecording ? .red : .blue
    }
    
    private var backgroundColor: Color {
        if !audioRecorder.hasPermission {
            return Color(.systemGray5)
        }
        
        if audioRecorder.isUploading {
            return Color.orange.opacity(0.3)
        }
        
        return audioRecorder.isRecording ? Color.red.opacity(0.3) : Color.blue.opacity(0.2)
    }
}

// MARK: - Previews
#Preview("Default State") {
    MicrophoneButton(audioRecorder: AudioRecorder(apiMiddleware: APIMiddleware()))
}

#Preview("Recording State") {
    let recorder = AudioRecorder(apiMiddleware: APIMiddleware())
    recorder.isRecording = true
    return MicrophoneButton(audioRecorder: recorder)
}

#Preview("Uploading State") {
    let recorder = AudioRecorder(apiMiddleware: APIMiddleware())
    recorder.isUploading = true
    return MicrophoneButton(audioRecorder: recorder)
}

#Preview("Disabled State") {
    let recorder = AudioRecorder(apiMiddleware: APIMiddleware())
    recorder.hasPermission = false
    return MicrophoneButton(audioRecorder: recorder)
} 
//
//  MicrophoneButton.swift
//  Junie
//
//  Created by Ahmed Elsaeed on 24/05/2025.
//

import SwiftUI

/// A reusable microphone button component that handles recording state and user interactions.
struct MicrophoneButton: View {
    @ObservedObject var audioRecorder: AudioRecorder
    
    var body: some View {
        Image(systemName: "mic.fill")
            .font(.system(size: 60))
            .foregroundColor(buttonColor)
            .padding(20)
            .background(Circle().fill(backgroundColor))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if audioRecorder.hasPermission && !audioRecorder.isRecording {
                            audioRecorder.startRecording()
                        }
                    }
                    .onEnded { _ in
                        if audioRecorder.isRecording {
                            audioRecorder.stopRecording()
                        }
                    }
            )
            .disabled(!audioRecorder.hasPermission)
            .shadow(radius: audioRecorder.isRecording ? 10 : 5)
    }
    
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
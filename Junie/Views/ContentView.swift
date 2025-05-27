//
//  ContentView.swift
//  Junie
//
//  Created by Ahmed Elsaeed on 24/05/2025.
//

import SwiftUI
import AVFAudio

/// The main view of the application that handles the recording interface and permissions.
struct ContentView: View {
    @StateObject private var audioRecorder: AudioRecorder
    @State private var showPermissionAlert = false
    
    var body: some View {
        VStack {
            Text("Hello, Junie!")
            Spacer()
            MicrophoneButton(audioRecorder: audioRecorder)
        }
        .padding()
        .onAppear(perform: checkMicrophonePermission)
        .alert("Microphone Access Required", isPresented: $showPermissionAlert) {
            Button("Cancel") { }
            Button("Open Settings") {
                openSettings()
            }
        } message: {
            Text("Junie needs access to your microphone to record audio. Please enable microphone access in Settings.")
        }
    }
    
    private func checkMicrophonePermission() {
        guard !audioRecorder.hasPermission else { return }
        
        audioRecorder.requestMicrophonePermission { granted in
            if !granted && AVAudioApplication.shared.recordPermission == .denied {
                showPermissionAlert = true
            }
        }
    }
    
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
    
    init() {
        let apiMiddleware = APIMiddleware()
        _audioRecorder = StateObject(wrappedValue: AudioRecorder(apiMiddleware: apiMiddleware))
    }
}

// MARK: - Previews
#Preview("Default State") {
    ContentView()
} 
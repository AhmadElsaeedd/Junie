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
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        MainContentView(
            audioRecorder: audioRecorder,
            showPermissionAlert: $showPermissionAlert,
            showErrorAlert: $showErrorAlert,
            errorMessage: $errorMessage
        )
        .onAppear(perform: checkMicrophonePermission)
        .alert("Microphone Access Required", isPresented: $showPermissionAlert) {
            Button("Cancel") { }
            Button("Open Settings") {
                openSettings()
            }
        } message: {
            Text("Junie needs access to your microphone to record audio. Please enable microphone access in Settings.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func checkMicrophonePermission() {
        guard !audioRecorder.hasPermission else { return }
        
        audioRecorder.requestMicrophonePermission { granted in
            if !granted {
                if AVAudioApplication.shared.recordPermission == .denied {
                    self.showPermissionAlert = true
                } else {
                    self.errorMessage = "Failed to get microphone permission"
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            errorMessage = "Could not open settings"
            showErrorAlert = true
            return
        }
        
        guard UIApplication.shared.canOpenURL(url) else {
            errorMessage = "Settings cannot be opened"
            showErrorAlert = true
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    init() {
        let apiMiddleware = APIMiddleware()
        _audioRecorder = StateObject(wrappedValue: AudioRecorder(apiMiddleware: apiMiddleware))
    }
}

// MARK: - Supporting Views
private struct MainContentView: View {
    @ObservedObject var audioRecorder: AudioRecorder
    @Binding var showPermissionAlert: Bool
    @Binding var showErrorAlert: Bool
    @Binding var errorMessage: String
    
    var body: some View {
        VStack {
            Text("Hello, Junie!")
                .font(.title)
                .padding(.top)
            
            Spacer()
            
            MicrophoneButton(audioRecorder: audioRecorder)
                .padding(.bottom)
        }
        .padding()
    }
}

// MARK: - Previews
#Preview("Default State") {
    ContentView()
} 

//
//  ContentView.swift
//  Junie
//
//  Created by Ahmed Elsaeed on 24/05/2025.
//

import SwiftUI
import AVFAudio // Import AVFAudio for AVAudioApplication

struct ContentView: View {
    // Create APIMiddleware instance here, or it could be a shared instance passed down
    private var apiMiddleware = APIMiddleware() 
    @StateObject private var audioRecorder: AudioRecorder
    
    // State to manage the presentation of an alert if microphone access is denied.
    // Set to true when permission is denied and we want to inform the user.
    @State private var showPermissionAlert = false 

    var body: some View {
        VStack {
            Text("Hello, Junie!") // Updated text for a personal touch

            Spacer() // Pushes the microphone icon to the bottom

            // Microphone Button
            Image(systemName: "mic.fill")
                .font(.system(size: 60)) // Slightly larger icon for easier interaction
                .foregroundColor(micButtonColor)
                .padding(20) // Add some padding around the button for a larger tap area
                .background(Circle().fill(micButtonBackgroundColor)) // Subtle background for the button
                .gesture(
                    // Using DragGesture to detect press (onChanged) and release (onEnded)
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in // Called when the touch begins
                            if audioRecorder.hasPermission && !audioRecorder.isRecording {
                                audioRecorder.startRecording()
                            }
                        }
                        .onEnded { _ in // Called when the touch ends (finger lifted)
                            if audioRecorder.isRecording {
                                audioRecorder.stopRecording()
                            }
                        }
                )
                .disabled(!audioRecorder.hasPermission) // Disable button if microphone permission is not granted
                .shadow(radius: audioRecorder.isRecording ? 10 : 5) // Add a subtle shadow, more pronounced when recording
        }
        .padding()
        .onAppear {
            // When the view first appears, check microphone permissions.
            // AudioRecorder's init calls checkMicrophonePermission, which updates hasPermission.
            if !audioRecorder.hasPermission {
                // If permission hasn't been granted (i.e., it's .undetermined or .denied),
                // attempt to request it. The system prompt only appears if .undetermined.
                audioRecorder.requestMicrophonePermission { granted in
                    if !granted {
                        // If permission was not granted (either newly denied or previously denied).
                        if AVAudioApplication.shared.recordPermission == .denied {
                            print("Microphone permission is currently denied.")
                            // To actively prompt the user to go to settings, uncomment the line below:
                            self.showPermissionAlert = true
                        }
                    }
                }
            }
        }
        .alert("Microphone Access Required", isPresented: $showPermissionAlert) {
            Button("Cancel") { }
            Button("Open Settings") {
                // Directs the user to the app's settings page to enable microphone access.
                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Junie needs access to your microphone to record audio. Please enable microphone access in Settings.")
        }
    }
    
    // Computed property for microphone button color based on state
    private var micButtonColor: Color {
        if !audioRecorder.hasPermission {
            return .gray // Disabled state
        }
        return audioRecorder.isRecording ? .red : .blue // Recording vs. idle state
    }
    
    // Computed property for microphone button background color
    private var micButtonBackgroundColor: Color {
        if !audioRecorder.hasPermission {
            return Color(.systemGray5)
        }
        
        if audioRecorder.isUploading {
            return Color.orange.opacity(0.3)
        }
        
        return audioRecorder.isRecording ? Color.red.opacity(0.3) : Color.blue.opacity(0.2)
    }
    
    // Initializer to inject APIMiddleware into AudioRecorder
    init() {
        let apiMiddlewareInstance = APIMiddleware()
        _audioRecorder = StateObject(wrappedValue: AudioRecorder(apiMiddleware: apiMiddlewareInstance))
    }
}

#Preview {
    ContentView()
}

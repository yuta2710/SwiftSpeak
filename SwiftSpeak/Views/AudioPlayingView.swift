//
//  AudioPlayingView.swift
//  SwiftSpeak
//
//  Created by Nguyen Phuc Loi on 03/10/2024.
//

import SwiftUI

struct AudioRecorderView: View {
    @ObservedObject var audioRecorder = SpeechRecognizerV2()
    @State private var isRecording = false
    @State private var uploadedURL: URL?
    
    var body: some View {
        VStack {
            Text(isRecording ? "Recording..." : "Tap to Record")
                .foregroundColor(.red)
                .font(.headline)
                .padding()
            
            Button(action: {
                if self.audioRecorder.audioRecorder == nil {
                    self.audioRecorder.startRecording()
                } else {
                    self.audioRecorder.stopRecording()
                    self.uploadAudio()
                }
                self.isRecording.toggle()
            }) {
                Image(systemName: isRecording ? "stop.circle" : "circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.red)
            }
        }
    }
    
    func uploadAudio() {
        // Ensure we have the recorded file URL from the audioRecorder
        if let recordedFileURL = audioRecorder.audioRecorder?.url {
            let audioUploader = AudioUploader()
            audioUploader.uploadAudioFileToFirebase(audioFileURL: recordedFileURL) { result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        self.uploadedURL = url
                    }
                    print("File uploaded successfully: \(url.absoluteString)")
                case .failure(let error):
                    print("Failed to upload audio file: \(error.localizedDescription)")
                }
            }
        } else {
            print("No audio file to upload.")
        }
    }
}

#Preview {
    AudioRecorderView()
}

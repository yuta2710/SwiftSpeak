//
//  MeetingView.swift
//  Scrumdinger
//
//  Created by Nguyen Phuc Loi on 02/10/2024.
//

import SwiftUI

struct MeetingView: View {
    @StateObject var speechRecognizer = SpeechRecognizer()
        @State private var isRecording = false
        
        var body: some View {
            VStack {
                Text(speechRecognizer.transcript)
                    .padding()
                    .foregroundColor(.green)
                
//                Text("Words of speech: \(speechRecognizer.wordsPerSecond)")
//                    .padding()
//                    .foregroundColor(.blue)
                
                Text(speechRecognizer.speed)
                    .padding()
                    .foregroundColor(.red)
                    .bold()
                
                Button(action: {
                    if !isRecording {
                        speechRecognizer.transcribe()
                    } else {
                        speechRecognizer.stopTranscribing()
                    }
                    
                    isRecording.toggle()
                }) {
                    Text(isRecording ? "Stop" : "Record")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(isRecording ? Color.red : Color.blue)
                        .cornerRadius(10)
                }
            }
        }
}

#Preview {
    MeetingView()
}

//
//  MeetingView.swift
//  Scrumdinger
//
//  Created by Nguyen Phuc Loi on 02/10/2024.
//

import SwiftUI

struct MeetingView: View {
    @StateObject var speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        VStack {
            Text(speechRecognizer.transcript)
                .padding()
                .foregroundColor(.green)
            
            if !speechRecognizer.isRecording && speechRecognizer.canAnalyze {
                Text("Speech Speed: \(speechRecognizer.speed.rawValue)")
                    .padding()
                    .foregroundColor(.blue)
                
                Text("Words per minute: \(speechRecognizer.wordsPerMinute)")
                    .padding()
                    .foregroundColor(.red)
                    .bold()
            }
            
            Button(action: {
                if speechRecognizer.isRecording {
                    speechRecognizer.stopTranscribing()
                } else {
                    speechRecognizer.transcribe()
                }
            }) {
                Text(speechRecognizer.isRecording ? "Stop" : "Record")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(speechRecognizer.isRecording ? Color.red : Color.blue)
                    .cornerRadius(10)
            }
            
            if !speechRecognizer.isRecording && speechRecognizer.canAnalyze {
                Button(action: {
                    speechRecognizer.analyzeSpeedAndWPM()
                }) {
                    Text("Analyze")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
        }
        .alert(isPresented: $speechRecognizer.showUnclearSpeechAlert) {
            Alert(
                title: Text("Unclear Speech"),
                message: Text("Please speak more clearly and slowly."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// Previews
struct MeetingView_Previews: PreviewProvider {
    static var previews: some View {
        MeetingView()
    }
}

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
        VStack(spacing: 20) {
            TranscriptView(transcript: speechRecognizer.transcript)
            
            if speechRecognizer.isProcessing {
                ProgressView("Processing transcript...")
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            if !speechRecognizer.isRecording && !speechRecognizer.isProcessing {
                AnalysisView(speed: speechRecognizer.speed, wordsPerMinute: speechRecognizer.wordsPerMinute)
            }
            
            ControlButtonsView(
                isRecording: speechRecognizer.isRecording,
                canAnalyze: speechRecognizer.canAnalyze,
                onRecordTap: {
                    if speechRecognizer.isRecording {
                        speechRecognizer.stopTranscribing()
                    } else {
                        speechRecognizer.transcribe()
                    }
                },
                onAnalyzeTap: {
                    speechRecognizer.analyzeSpeedAndWPM()
                }
            )
            
            if let errorMessage = speechRecognizer.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .navigationTitle("Speech Analyzer")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $speechRecognizer.showUnclearSpeechAlert) {
            Alert(
                title: Text("Unclear Speech"),
                message: Text("Please speak more clearly and slowly."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct TranscriptView: View {
    let transcript: String
    
    var body: some View {
        ScrollView {
            Text(transcript)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 200)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct AnalysisView: View {
    let speed: SpeechSpeed
    let wordsPerMinute: Int
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Speech Speed: \(speed.rawValue)")
                .font(.headline)
            
            Text("Words per minute: \(wordsPerMinute)")
                .font(.subheadline)
            
            ProgressView(value: Double(wordsPerMinute), total: 250)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 10)
                .accentColor(speedColor)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    var speedColor: Color {
        switch speed {
        case .Slow:
            return .blue
        case .Normal:
            return .green
        case .Fast:
            return .orange
        case .VeryFast:
            return .red
        case .Unclear:
            return .yellow
        }
    }
}

struct ControlButtonsView: View {
    let isRecording: Bool
    let canAnalyze: Bool
    let onRecordTap: () -> Void
    let onAnalyzeTap: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: onRecordTap) {
                Text(isRecording ? "Stop" : "Record")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(minWidth: 100)
                    .background(isRecording ? Color.red : Color.blue)
                    .cornerRadius(10)
            }
            
            Button(action: onAnalyzeTap) {
                Text("Analyze")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(minWidth: 100)
                    .background(canAnalyze ? Color.green : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(!canAnalyze)
        }
    }
}

struct MeetingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MeetingView()
        }
    }
}

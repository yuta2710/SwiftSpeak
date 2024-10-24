//
//  MeetingView.swift
//  Scrumdinger
//
//  Created by Nguyen Phuc Loi on 02/10/2024.
//

import SwiftUI
import RiveRuntime

struct MeetingView: View {
    @ObservedObject var speechRecognizer: SpeechRecognizer
    @State private var showingSaveDialog = false
    @State private var recordingName = ""
    @State private var isShowingDetailView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(alignment: .trailing) {
                    Image("Background01")
                        .resizable()
                        .frame(width: 250, height: 600, alignment: .topTrailing)
                        .ignoresSafeArea()
                    
                    RiveViewModel(fileName: "shapes").view()
                        .ignoresSafeArea()
                        .blur(radius: 50)
                        .background(
                            Image("Spline")
                                .resizable()
                                .blur(radius: 50)
                                .offset(x: 200, y: 100)
                        )
                }
                RiveViewModel(fileName: "shapes").view()
                    .ignoresSafeArea()
                    .blur(radius: 50)
                    .background(
                        Image("Spline")
                            .resizable()
                            .blur(radius: 50)
                            .offset(x: 200, y: 100)
                    )
                
                
                VStack(spacing: 20) {
                    if !speechRecognizer.transcript.isEmpty {
                        TranscriptView(transcript: speechRecognizer.transcript)
                    }
                    
                    
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
                        isPlaybackAvailable: speechRecognizer.isPlaybackAvailable,
                        isPlaying: speechRecognizer.isPlaying,
                        onRecordTap: {
                            if speechRecognizer.isRecording {
                                speechRecognizer.stopTranscribing()
                            } else {
                                speechRecognizer.transcribe()
                            }
                        },
                        onAnalyzeTap: {
                            speechRecognizer.analyzeSpeedAndWPM()
                        },
                        onPlaybackTap: {
                            if speechRecognizer.isPlaying {
                                speechRecognizer.stopPlayback()
                            } else {
                                speechRecognizer.playRecording()
                            }
                        }
                    )
                    
                    if let errorMessage = speechRecognizer.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    if !speechRecognizer.isRecording && !speechRecognizer.isProcessing && speechRecognizer.isPlaybackAvailable {
                        Button("Save Recording") {
                            showingSaveDialog = true
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding()
                .navigationTitle("Record Area")
                .navigationBarTitleDisplayMode(.large)
                .alert("Save Recording", isPresented: $showingSaveDialog) {
                    TextField("Recording Name", text: $recordingName)
                    
                    Button("Save") {
                        speechRecognizer.saveRecording(name: recordingName) { success in
                            if success {
                                // If save and load are successful, trigger the navigation
                                print("Is success \(success)")
                                self.speechRecognizer.loadRecordings()
                                self.isShowingDetailView = true
                                recordingName = ""
                            } else {
                                // Handle error if needed (e.g., show an error message)
                                print("Failed to save recording")
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Enter a name for your recording")
                }
                .padding()
                //            .background(Color(.systemBackground))
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding()
                .navigationTitle("Speech Analyzer")
                .navigationBarTitleDisplayMode(.inline)
                .alert(isPresented: $speechRecognizer.showUnclearSpeechAlert) {
                    Alert(
                        title: Text("Unclear Speech"),
                        message: Text("Please speak more clearly and slowly."),
                        dismissButton: .default(Text("OK"))
                    )
                }
                
                NavigationLink(
                    destination: DetailedRecordingView(
                        recording: self.speechRecognizer.selectedRecord!,
                        speechRecognizer: speechRecognizer
                    ),
                    isActive: $isShowingDetailView
                ) {
                    EmptyView()
                }
                
            }
            .onAppear {
                DispatchQueue.main.async {
                    speechRecognizer.loadRecordings()
                }
            }
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
        .background(.thinMaterial)
        .cornerRadius(4)
    }
}

struct AnalysisView: View {
    let speed: SpeechSpeed
    let wordsPerMinute: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading) {
                Text("Speech Speed: \(speed.rawValue)")
                    .font(.title2)
                    .bold()
                
                Text("Words per minute: \(wordsPerMinute)")
                    .font(.subheadline)
            }
            
            ProgressView(value: Double(wordsPerMinute), total: 250)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 10)
                .accentColor(speedColor)
        }
        
        .padding()
        //        .background(Color(.systemGray6))
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 0, style: .continuous))
        .cornerRadius(10)
        
        //        ZStack {
        //            LinearGradient(gradient: Gradient(stops: [
        //                .init(color: Color("PrimaryBackground"), location: 0.0),    //
        //                  ]), startPoint: .topLeading, endPoint: .bottomTrailing)
        //                  .cornerRadius(30)
        //            VStack {
        //                // Content of the card goes here
        //                Text("Featured")
        //                    .font(.title)
        //                    .fontWeight(.bold)
        //                    .foregroundColor(.black)
        //
        //                Spacer()
        //            }
        //            .padding()
        //        }
        //        .frame(width: 350, height: 350)
        //        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
        
        
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
    let isPlaybackAvailable: Bool
    let isPlaying: Bool
    let onRecordTap: () -> Void
    let onAnalyzeTap: () -> Void
    let onPlaybackTap: () -> Void
    
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
            .shadow(color: .blue, radius: 4, x: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, y: 2)
            
            Button(action: onAnalyzeTap) {
                Text("Analyze")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(minWidth: 100)
                    .background(canAnalyze ? Color.green : Color(hex: "000000"))
                    .cornerRadius(10)
            }
            .disabled(!canAnalyze)
            .shadow(
                color: canAnalyze ? Color.green : Color(hex: "292782"), radius: 4, x: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, y: 2)
            .background(.ultraThinMaterial)
            
        }
        
        if isPlaybackAvailable {
            Button(action: onPlaybackTap) {
                HStack {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    Text(isPlaying ? "Pause" : "Play Recording")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(minWidth: 200)
                .background(Color.orange)
                .cornerRadius(10)
            }
        }
        
        
    }
}

struct MeetingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MeetingView(speechRecognizer: SpeechRecognizer())
        }
    }
}

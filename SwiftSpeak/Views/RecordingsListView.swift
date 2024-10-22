//
//  File.swift
//  SwiftSpeak
//
//  Created by Xuan Loc on 17/10/24.
//

import SwiftUI
import AVFoundation

struct RecordingsListView: View {
  @EnvironmentObject var speechRecognizer: SpeechRecognizer
  @Environment(\.colorScheme) var systemScheme
  
  @State private var selectedRecording: RecordingMetadata?
  @State var t: Float = 0.0
  @State var timer: Timer?
  
  var body: some View {
    NavigationView {
      ZStack {
        if systemScheme == .dark {
//          LinearGradient(gradient: Gradient(stops: [
//            .init(color: Color(hex: "#BA1FEE"), location: -0.5),
//            .init(color: Color(hex: "#000000"), location: 0.5),
//            .init(color: Color(hex: "#031341"), location: 1),
//            .init(color: Color(hex: "#000000"), location: 0.5)
//          ]), startPoint: .topLeading, endPoint: .bottomTrailing)
//          .ignoresSafeArea()
        }else {
          Color.white
            .ignoresSafeArea()
        }
        
        VStack {
          List {
            ForEach(speechRecognizer.recordings, id: \.id) { recording in
              NavigationLink(destination: DetailedRecordingView(recording: recording, speechRecognizer: speechRecognizer)) {
                VStack(alignment: .leading) {
                  Text(recording.name)
                    .font(.headline)
                    .foregroundColor(systemScheme == .dark ? .white : .black)
                  Text(recording.timestamp, style: .date)
                    .font(.subheadline)
                    .foregroundColor(systemScheme == .dark ? .white : .black)
                  Text("Duration: \(formattedDuration(recording.duration))")
                    .font(.subheadline)
                    .foregroundColor(systemScheme == .dark ? .white : .black)
                }
//                .background(.red)
              }
            }
          }
        }
      }
      .navigationTitle("Recordings")
      .onAppear() {
        speechRecognizer.loadRecordings()
      }
    }
  }
  
  private func formattedDuration(_ duration: TimeInterval) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.unitsStyle = .abbreviated
    return formatter.string(from: duration) ?? ""
  }
  
  
  func sinInRange(_ range: ClosedRange<Float>, _ offset: Float, _ timeScale: Float, _ t: Float) -> Float {
    let amplitude = (range.upperBound - range.lowerBound) / 2
    let midPoint = (range.upperBound + range.lowerBound) / 2
    return midPoint + amplitude * sin(timeScale * t + offset)
  }
}

struct DetailedRecordingView: View {
  let recording: RecordingMetadata
  @ObservedObject var speechRecognizer: SpeechRecognizer
  
  @State private var isPlaying = false
  @State private var audioPlayer: AVAudioPlayer?
  @State private var showingDeleteAlert = false
  @State private var showingShareSheet = false
  
  @Environment(\.dismiss) var dismiss
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text(recording.name)
          .font(.title)
        
        Text("Recorded on: \(recording.timestamp, style: .date)")
        Text("Duration: \(formattedDuration(recording.duration))")
        Text("Words per minute: \(recording.wordsPerMinute)")
        Text("Speech speed: \(recording.speechSpeed.rawValue)")
        
        Text("Transcript:")
          .font(.headline)
        Text(recording.transcript)
          .padding()
          .background(Color.gray.opacity(0.1))
          .cornerRadius(8)
        
        HStack {
          Button(action: togglePlayback) {
            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
              .resizable()
              .frame(width: 44, height: 44)
          }
          
          Button(action: { showingShareSheet = true }) {
            Image(systemName: "square.and.arrow.up")
              .resizable()
              .frame(width: 44, height: 44)
          }
          
          Button(action: { showingDeleteAlert = true }) {
            Image(systemName: "trash")
              .resizable()
              .frame(width: 44, height: 44)
              .foregroundColor(.red)
          }
        }
        .padding()
      }
      .padding()
    }
    .navigationTitle("Recording Details")
    .alert("Delete Recording", isPresented: $showingDeleteAlert) {
      Button("Delete", role: .destructive) {
        speechRecognizer.deleteRecording(id: recording.id) {
          // navigate back to the previous screen
          dismiss()
        }
      }
      Button("Cancel", role: .cancel) {
        
      }
    } message: {
      Text("Are you sure you want to delete this recording?")
    }
    .sheet(isPresented: $showingShareSheet) {
      ActivityViewController(activityItems: [URL(string: recording.storageUrl)!])
    }
    .onDisappear {
      audioPlayer?.stop()
    }
  }
  
  private func togglePlayback() {
    if isPlaying {
      audioPlayer?.pause()
    } else {
      if audioPlayer == nil {
        do {
          let url = URL(string: recording.storageUrl)!
          let data = try Data(contentsOf: url)
          audioPlayer = try AVAudioPlayer(data: data)
          audioPlayer?.prepareToPlay()
        } catch {
          print("Error setting up audio player: \(error.localizedDescription)")
        }
      }
      audioPlayer?.play()
    }
    isPlaying.toggle()
  }
  
  private func formattedDuration(_ duration: TimeInterval) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.unitsStyle = .abbreviated
    return formatter.string(from: duration) ?? ""
  }
}

struct ActivityViewController: UIViewControllerRepresentable {
  let activityItems: [Any]
  let applicationActivities: [UIActivity]? = nil
  
  func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    return controller
  }
  
  func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}


#Preview {
  RecordingsListView()
    .environmentObject(AuthenticationManager())
    .environmentObject(SpeechRecognizer())
}

//@State var t: Float = 0.0
//@State var timer: Timer?
//
//var body: some View {
//  ZStack {
//    MeshGradient(
//      width: 3,
//      height: 3,
//      points: [
//        [0.0, 0.0],
//        [0.5, 0.0],
//        [1.0, 0.0],
//        [sinInRange(-0.8...(-0.2), 0.439, 0.342, t), sinInRange(0.3...0.7, 3.42, 0.984, t)],
//        [sinInRange(0.1...0.8, 0.239, 0.084, t), sinInRange(0.2...0.8, 5.21, 0.242, t)],
//        [sinInRange(1.0...1.5, 0.939, 0.684, t), sinInRange(0.4...0.8, 0.25, 0.642, t)],
//
//        [sinInRange(-0.8...0.0, 1.439, 0.442, t), sinInRange(1.4...1.9, 3.42, 0.984, t)],
//        [sinInRange(0.3...0.6, 0.339, 0.784, t), sinInRange(1.0...1.2, 1.22, 0.772, t)],
//        [sinInRange(1.0...1.5, 0.939, 0.056, t), sinInRange(1.3...1.7, 0.47, 0.342, t)]
//      ],
//      colors: [
//        .black, .black, .black,
//        .orange, .red, .orange,
//        .indigo, .black, .green
//      ],
//      background: .black)
//    .ignoresSafeArea()
//
//  }
//  .onAppear {
//    timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { _ in
//      t += 0.02
//    })
//  }
//
//
//}
//
//func sinInRange(_ range: ClosedRange<Float>, _ offset: Float, _ timeScale: Float, _ t: Float) -> Float {
//  let amplitude = (range.upperBound - range.lowerBound) / 2
//  let midPoint = (range.upperBound + range.lowerBound) / 2
//  return midPoint + amplitude * sin(timeScale * t + offset)
//}

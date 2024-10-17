//
//  File.swift
//  SwiftSpeak
//
//  Created by Xuan Loc on 17/10/24.
//

import SwiftUI
import AVFoundation

struct RecordingsListView: View {
	@ObservedObject var speechRecognizer: SpeechRecognizer
	@State private var selectedRecording: RecordingMetadata?
	
	var body: some View {
		NavigationView {
			List {
				ForEach(speechRecognizer.recordings, id: \.id) { recording in
					NavigationLink(destination: DetailedRecordingView(recording: recording, speechRecognizer: speechRecognizer)) {
						VStack(alignment: .leading) {
							Text(recording.name)
								.font(.headline)
							Text(recording.timestamp, style: .date)
								.font(.subheadline)
							Text("Duration: \(formattedDuration(recording.duration))")
								.font(.subheadline)
						}
					}
				}
			}
			.navigationTitle("Recordings")
			.onAppear {
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
}

struct DetailedRecordingView: View {
	let recording: RecordingMetadata
	@ObservedObject var speechRecognizer: SpeechRecognizer
	@State private var isPlaying = false
	@State private var audioPlayer: AVAudioPlayer?
	@State private var showingDeleteAlert = false
	@State private var showingShareSheet = false
	
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
				speechRecognizer.deleteRecording(id: recording.id)
			}
			Button("Cancel", role: .cancel) {}
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

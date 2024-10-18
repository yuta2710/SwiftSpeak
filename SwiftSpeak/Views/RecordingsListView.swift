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
      
    }
    .onAppear {
      // Explicitly reload recordings whenever this view appears
      DispatchQueue.main.async {
        print("Size of recordings before updated on record list view \(speechRecognizer.recordings.count)")
        speechRecognizer.loadRecordings()
        print("Size of recordings after updated on record list view \(speechRecognizer.recordings.count)")
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
	@State private var showingExportAlert = false
	@State private var exportAlertMessage = ""
	@State private var isLoading = false
	@State private var exportedFileURL: URL?

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
					.disabled(isLoading)
					
					Button(action: { showingShareSheet = true }) {
						Image(systemName: "square.and.arrow.up")
							.resizable()
							.frame(width: 44, height: 44)
					}
					
					Button(action: exportRecording) {
						Image(systemName: "arrow.down.circle")
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
				
				if isLoading {
					ProgressView("Exporting...")
				}
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
		.alert("Export Recording", isPresented: $showingExportAlert) {
			Button("OK", role: .cancel) {}
		} message: {
			Text(exportAlertMessage)
		}
		.onDisappear {
			audioPlayer?.stop()
		}
		.onAppear {
			setupAudioPlayer()
		}
	}
	
	private func setupAudioPlayer() {
		isLoading = true
		DispatchQueue.global(qos: .background).async {
			do {
				let url = URL(string: self.recording.storageUrl)!
				let data = try Data(contentsOf: url)
				DispatchQueue.main.async {
					do {
						self.audioPlayer = try AVAudioPlayer(data: data)
						self.audioPlayer?.prepareToPlay()
					} catch {
						print("Error setting up audio player: \(error.localizedDescription)")
					}
					self.isLoading = false
				}
			} catch {
				print("Error downloading audio data: \(error.localizedDescription)")
				DispatchQueue.main.async {
					self.isLoading = false
				}
			}
		}
	}
	
	private func togglePlayback() {
		if isPlaying {
			audioPlayer?.pause()
		} else {
			audioPlayer?.play()
		}
		isPlaying.toggle()
	}
	
	private func exportRecording() {
		isLoading = true
		speechRecognizer.exportRecording(recording) { result in
			isLoading = false
			switch result {
			case .success(let url):
				exportedFileURL = url
				exportAlertMessage = "Recording exported successfully to Downloads folder.\nFile: \(url.lastPathComponent)\nLocation: \(url.deletingLastPathComponent().path)"
			case .failure(let error):
				exportAlertMessage = "Error exporting recording: \(error.localizedDescription)"
			}
			showingExportAlert = true
		}
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

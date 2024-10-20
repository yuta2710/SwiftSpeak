//
//  MeetingView.swift
//  Scrumdinger
//
//  Created by Nguyen Phuc Loi on 02/10/2024.
//

import RiveRuntime
import SwiftUI
import UniformTypeIdentifiers

struct MeetingView: View {
	@ObservedObject var speechRecognizer: SpeechRecognizer
	@State private var showingSaveDialog = false
	@State private var recordingName = ""
	@State private var isImporting = false

	var body: some View {
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

				if !speechRecognizer.isRecording
					&& !speechRecognizer.isProcessing
				{
					AnalysisView(
						speed: speechRecognizer.speed,
						wordsPerMinute: speechRecognizer.wordsPerMinute)
				}

				if !speechRecognizer.isRecording
					&& !speechRecognizer.isProcessing
				{
					Button(action: {
						isImporting = true
					}) {
						HStack {
							Image(systemName: "square.and.arrow.down")
							Text("Import Recording")
						}
						.padding()
						.background(Color.blue)
						.foregroundColor(.white)
						.cornerRadius(10)
					}
					.fileImporter(
						isPresented: $isImporting,
						allowedContentTypes: [UTType.audio],
						allowsMultipleSelection: false
					) { result in
						do {
							let selectedFile = try result.get().first!
							if selectedFile.startAccessingSecurityScopedResource()
							{
								defer {
									selectedFile
										.stopAccessingSecurityScopedResource()
								}
								try speechRecognizer.importRecording(
									from: selectedFile)
							} else {
								throw NSError(
									domain: "AccessError", code: 1,
									userInfo: [
										NSLocalizedDescriptionKey:
											"Failed to access the file."
									])
							}
						} catch {
							print(
								"Error importing file: \(error.localizedDescription)"
							)
							// Show error alert to user
						}
					}
				}

				ControlButtonsView(
					isRecording: speechRecognizer.isRecording,
					canAnalyze: speechRecognizer.canAnalyze,
					isPlaybackAvailable: speechRecognizer.isPlaybackAvailable,
					isPlaying: speechRecognizer.isPlaying,
					onRecordStart: {
						// Start recording logic
						speechRecognizer.transcribe()
					},
					onRecordStop: {
						// Stop recording logic
						speechRecognizer.stopTranscribing()
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

				if !speechRecognizer.isRecording
					&& !speechRecognizer.isProcessing
					&& speechRecognizer.isPlaybackAvailable
				{
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
			.background(
				.thinMaterial,
				in: RoundedRectangle(cornerRadius: 24, style: .continuous)
			)
			.padding()
			.navigationTitle("Record Area")
			.navigationBarTitleDisplayMode(.large)
			.alert("Save Recording", isPresented: $showingSaveDialog) {
				TextField("Recording Name", text: $recordingName)
				Button("Save") {
					speechRecognizer.saveRecording(name: recordingName)
					recordingName = ""
				}
				Button("Cancel", role: .cancel) {}
			} message: {
				Text("Enter a name for your recording")
			}
			.padding()
			//            .background(Color(.systemBackground))
			.background(
				.thinMaterial,
				in: RoundedRectangle(cornerRadius: 24, style: .continuous)
			)
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
		}
		.onAppear {
			DispatchQueue.main.async {
				speechRecognizer.loadRecordings()
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
		.background(
			.thinMaterial,
			in: RoundedRectangle(cornerRadius: 0, style: .continuous)
		)
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
	let isPlaybackAvailable: Bool
	let isPlaying: Bool
	let onRecordStart: () -> Void
	let onRecordStop: () -> Void
	let onAnalyzeTap: () -> Void
	let onPlaybackTap: () -> Void

	@State private var isHolding = false

	var body: some View {
		VStack(spacing: 20) {
			// Record button with hold gesture
			Circle()
				.fill(isHolding ? Color.red : Color.blue)
				.frame(width: 80, height: 80)
				.overlay(
					Image(systemName: "mic.fill")
						.foregroundColor(.white)
						.font(.system(size: 40))
				)
				.gesture(
					DragGesture(minimumDistance: 0)
						.onChanged { _ in
							if !isHolding {
								isHolding = true
								onRecordStart()  // Start recording
							}
						}
						.onEnded { _ in
							isHolding = false
							onRecordStop()  // Stop recording
						}
				)

			// Show Analyze button after recording
			if !isRecording && canAnalyze {
				Button(action: onAnalyzeTap) {
					Text("Analyze")
						.font(.headline)
						.foregroundColor(.white)
						.padding()
						.frame(minWidth: 100)
						.background(Color.green)
						.cornerRadius(10)
				}
				.shadow(color: .green, radius: 4, x: 0, y: 2)
			}

			// Playback controls
			if isPlaybackAvailable {
				Button(action: onPlaybackTap) {
					HStack {
						Image(
							systemName: isPlaying ? "pause.fill" : "play.fill")
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
		.padding()
	}
}

struct MeetingView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationView {
			MeetingView(speechRecognizer: SpeechRecognizer())
		}
	}
}

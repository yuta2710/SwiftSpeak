//
//  SpeechRecognizer.swift
//  Scrumdinger
//
//  Created by Nguyen Phuc Loi on 02/10/2024.
//

import AVFoundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation
import Speech
import SwiftUI

enum SpeechSpeed: String, Codable {
  case Slow = "Slow"
  case Normal = "Normal"
  case Fast = "Fast"
  case VeryFast = "Very Fast"
  case Unclear = "Unclear"
}

struct RecordingMetadata: Codable {
  let id: String
  let name: String
  let timestamp: Date
  let duration: TimeInterval
  let wordsPerMinute: Int
  let speechSpeed: SpeechSpeed
  let transcript: String
  let storageUrl: String
}

class SpeechRecognizer: NSObject, ObservableObject {
  enum RecognizerError: Error {
    case nilRecognizer
    case notAuthorizedToRecognize
    case notPermittedToRecord
    case recognizerIsUnavailable
    case transcriptionFailed(String)
    
    var message: String {
      switch self {
      case .nilRecognizer: return "Can't initialize speech recognizer"
      case .notAuthorizedToRecognize:
        return "Not authorized to recognize speech"
      case .notPermittedToRecord: return "Not permitted to record audio"
      case .recognizerIsUnavailable: return "Recognizer is unavailable"
      case .transcriptionFailed(let details):
        return "Transcription failed: \(details)"
      }
    }
  }
  
  @Published var transcript: String = ""
  @Published var speed: SpeechSpeed = .Normal
  @Published var wordsPerMinute: Int = 0
  @Published var isRecording: Bool = false
  @Published var isProcessing: Bool = false
  @Published var canAnalyze: Bool = false
  @Published var errorMessage: String? = nil
  @Published var showUnclearSpeechAlert: Bool = false
  @Published var isPlaybackAvailable: Bool = false
  @Published var isPlaying: Bool = false
  @Published var recordings: [RecordingMetadata] = []
  @Published var exportMessage: String = ""
  
  private let storage = Storage.storage()
  private let db = Firestore.firestore()
  private var audioEngine: AVAudioEngine?
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private let recognizer: SFSpeechRecognizer?
  private let audioSession = AVAudioSession.sharedInstance()
  
  private var startTime: Date?
  private var wordCount: Int = 0
  private var isFinalizing: Bool = false
  private var lastTranscriptUpdate: Date?
  private let unclearSpeechThreshold: TimeInterval = 3.0  // 3 seconds
  
  private var audioRecorder: AVAudioRecorder?
  private var audioPlayer: AVAudioPlayer?
  private var audioFileURL: URL?
  
  override init() {
    recognizer = SFSpeechRecognizer()
    super.init()
    
    self.loadRecordings()
    
    Task(priority: .background) {
      do {
        guard recognizer != nil else {
          throw RecognizerError.nilRecognizer
        }
        guard await SFSpeechRecognizer.hasAuthorizationToRecognize()
        else {
          throw RecognizerError.notAuthorizedToRecognize
        }
        guard
          await AVAudioSession.sharedInstance()
            .hasPermissionToRecord()
        else {
          throw RecognizerError.notPermittedToRecord
        }
      } catch {
        speakError(error)
      }
    }
  }
  
  deinit {
    reset()
  }
  
  private func reset() {
    task?.cancel()
    audioEngine?.stop()
    audioEngine = nil
    request = nil
    task = nil
    audioRecorder?.stop()
    audioPlayer?.stop()
    isPlaying = false
    
    do {
      try audioSession.setActive(
        false, options: .notifyOthersOnDeactivation)
    } catch {
      print("Failed to deactivate audio session: \(error)")
    }
  }
  
  /**
   Begin transcribing audio.
   
   Creates a `SFSpeechRecognitionTask` that transcribes speech to text until you call `stopTranscribing()`.
   The resulting transcription is continuously written to the published `transcript` property.
   */
  
  /// Begins transcribing audio and analyzing speech speed
  func transcribe() {
    DispatchQueue(label: "Speech Recognizer Queue", qos: .background).async
    { [weak self] in
      guard let self = self, let recognizer = self.recognizer,
            recognizer.isAvailable
      else {
        self?.speakError(RecognizerError.recognizerIsUnavailable)
        return
      }
      
      do {
        try self.audioSession.setCategory(
          .playAndRecord, mode: .default,
          options: [.defaultToSpeaker, .mixWithOthers])
        try self.audioSession.setActive(
          true, options: .notifyOthersOnDeactivation)
        
        let (audioEngine, request) = try Self.prepareEngine()
        self.audioEngine = audioEngine
        self.request = request
        self.startTime = Date()
        self.wordCount = 0
        self.isFinalizing = false
        self.lastTranscriptUpdate = Date()
        
        // Set up audio recording
        let documentsPath = FileManager.default.urls(
          for: .documentDirectory, in: .userDomainMask)[0]
        self.audioFileURL = documentsPath.appendingPathComponent(
          "speechRecording.m4a")
        let settings = [
          AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
          AVSampleRateKey: 44100,
          AVNumberOfChannelsKey: 2,
          AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        self.audioRecorder = try AVAudioRecorder(
          url: self.audioFileURL!, settings: settings)
        self.audioRecorder?.record()
        
        self.task = recognizer.recognitionTask(with: request) {
          [weak self] result, error in
          guard let self = self else { return }
          
          if let result = result {
            self.updateTranscript(result.bestTranscription)
            if result.isFinal {
              self.finishTranscribing()
            }
          }
          
          if let error = error {
            if !self.isFinalizing {
              print(
                "Recognition error: \(error.localizedDescription)"
              )
              // Only treat as an error if we haven't received any transcription
              if self.transcript.isEmpty {
                self.speakError(
                  RecognizerError.transcriptionFailed(
                    error.localizedDescription))
              }
            }
          }
        }
        
        DispatchQueue.main.async {
          self.isRecording = true
          self.canAnalyze = false
          self.errorMessage = nil
          self.showUnclearSpeechAlert = false
          self.isPlaybackAvailable = false
        }
      } catch {
        self.reset()
        self.speakError(error)
      }
    }
  }
	/// Importing a voice record into the app from local devices
	func importRecording(from url: URL) throws {
		let audioData = try Data(contentsOf: url)
		guard audioData.count <= 10 * 1024 * 1024 else { // 10MB limit (self set)
			throw NSError(domain: "ImportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "File size exceeds \(audioData.count)MB limit."])
		}
		
		let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
		try audioData.write(to: tempURL)
		
		let audioPlayer = try AVAudioPlayer(contentsOf: tempURL)
		let duration = audioPlayer.duration
		
		/// Perform speech recognition
		let recognizer = SFSpeechRecognizer()
		let request = SFSpeechURLRecognitionRequest(url: tempURL)
		
		recognizer?.recognitionTask(with: request) { [weak self] (result, error) in
			guard let self = self else { return }
			
			if let error = error {
				DispatchQueue.main.async {
					self.errorMessage = "Unable to transcribe: \(error.localizedDescription)"
				}
				return
			}
			
			guard let result = result, result.isFinal else { return }
			
			let transcript = result.bestTranscription.formattedString
			let wordCount = transcript.split(separator: " ").count
			let wordsPerMinute = Int(Double(wordCount) / (duration / 60.0))
			let speed = self.categorizeSpeechSpeed(wordsPerMinute: wordsPerMinute)
			
			DispatchQueue.main.async {
				self.transcript = transcript
				self.wordsPerMinute = wordsPerMinute
				self.speed = speed
				self.canAnalyze = true
				self.isPlaybackAvailable = true
			}
			
			/// Save the recording to Firebase
			self.saveImportedRecording(url: tempURL, transcript: transcript, duration: duration, wordsPerMinute: wordsPerMinute, speed: speed)
		}
	}
	
	/// Save the recording into Firebase with M4A file format
	private func saveImportedRecording(url: URL, transcript: String, duration: TimeInterval, wordsPerMinute: Int, speed: SpeechSpeed) {
		guard let userId = Auth.auth().currentUser?.uid else { return }
		
		let recordId = UUID().uuidString
		let storageRef = storage.reference().child("recordings/\(userId)/\(recordId).m4a")
		
		storageRef.putFile(from: url, metadata: nil) { metadata, error in
			if let error = error {
				print("Error uploading file: \(error.localizedDescription)")
				return
			}
			
			storageRef.downloadURL { url, error in
				guard let downloadURL = url else {
					print("Error getting download URL: \(error?.localizedDescription ?? "Unknown error")")
					return
				}
				
				let metadata = RecordingMetadata(
					id: recordId,
					name: "Imported Recording",
					timestamp: Date(),
					duration: duration,
					wordsPerMinute: wordsPerMinute,
					speechSpeed: speed,
					transcript: transcript,
					storageUrl: downloadURL.absoluteString
				)
				
				self.saveMetadataToFirestore(metadata: metadata)
				
				DispatchQueue.main.async {
					self.recordings.append(metadata)
					self.recordings.sort { $0.timestamp > $1.timestamp }
				}
			}
		}
	}
	
	/// Export the recording after save the recording in the app
	func exportRecording(_ recording: RecordingMetadata, completion: @escaping (Result<URL, Error>) -> Void) {
		guard let url = URL(string: recording.storageUrl) else {
			completion(.failure(NSError(domain: "ExportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid recording URL"])))
			return
		}
		
		URLSession.shared.dataTask(with: url) { data, response, error in
			if let error = error {
				DispatchQueue.main.async {
					completion(.failure(error))
				}
				return
			}
			
			guard let data = data else {
				DispatchQueue.main.async {
					completion(.failure(NSError(domain: "ExportError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
				}
				return
			}
			
			do {
				let fileManager = FileManager.default
				let downloadsPath = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
				let destinationURL = downloadsPath.appendingPathComponent("\(recording.name).m4a")
				
				/// Remove the file if a file with the same name exists
				if fileManager.fileExists(atPath: destinationURL.path) {
					try fileManager.removeItem(at: destinationURL)
				}
				
				try data.write(to: destinationURL)
				DispatchQueue.main.async {
					completion(.success(destinationURL))
				}
			} catch {
				DispatchQueue.main.async {
					completion(.failure(error))
				}
			}
		}.resume()
	}
  
  /// Function to analyze the text WPM
  func analyzeSpeedAndWPM() {
    guard let startTime = self.startTime else { return }
    
    let elapsedTimeInMinutes = Date().timeIntervalSince(startTime) / 60.0
    let wordsPerMinute = max(
      0, Int(Double(self.wordCount) / elapsedTimeInMinutes))
    
    DispatchQueue.main.async {
      self.wordsPerMinute = wordsPerMinute
      self.speed = self.categorizeSpeechSpeed(
        wordsPerMinute: wordsPerMinute)
    }
  }
  
  /// Update transcript to get whole text in one session
  private func updateTranscript(_ transcription: SFTranscription) {
    DispatchQueue.main.async {
      self.transcript = transcription.formattedString
      let newWordCount = transcription.segments.count
      
      if newWordCount > self.wordCount {
        self.wordCount = newWordCount
        self.lastTranscriptUpdate = Date()
      } else {
        self.checkForUnclearSpeech()
      }
    }
  }
  
  /// Check for Optimus Prime oe oe oe
  private func checkForUnclearSpeech() {
    if let lastUpdate = lastTranscriptUpdate,
       Date().timeIntervalSince(lastUpdate) >= unclearSpeechThreshold
    {
      DispatchQueue.main.async {
        self.showUnclearSpeechAlert = true
      }
    }
  }
  
  /// Categorizes speech speed based on words per minute
  private func categorizeSpeechSpeed(wordsPerMinute: Int) -> SpeechSpeed {
    switch wordsPerMinute {
    case 0...119:
      return .Slow
    case 120...150:
      return .Normal
    case 151...200:
      return .Fast
    case 201...:
      return .VeryFast
    default:
      return .Unclear
    }
  }
  
  private static func prepareEngine() throws -> (
    AVAudioEngine, SFSpeechAudioBufferRecognitionRequest
  ) {
    let audioEngine = AVAudioEngine()
    
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true
    
    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(
      .record, mode: .measurement, options: .duckOthers)
    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    let inputNode = audioEngine.inputNode
    
    let recordingFormat = inputNode.outputFormat(forBus: 0)
    inputNode.installTap(
      onBus: 0, bufferSize: 1024, format: recordingFormat
    ) { buffer, _ in
      request.append(buffer)
    }
    audioEngine.prepare()
    try audioEngine.start()
    
    return (audioEngine, request)
  }
  
  private func speakError(_ error: Error) {
    DispatchQueue.main.async {
      if let recognizerError = error as? RecognizerError {
        self.errorMessage = recognizerError.message
      } else {
        self.errorMessage = error.localizedDescription
      }
      self.isRecording = false
      self.isProcessing = false
      self.canAnalyze = false
    }
  }
  
  /// Stops transcribing audio
  func stopTranscribing() {
    isFinalizing = true
    audioEngine?.stop()
    audioRecorder?.stop()
    request?.endAudio()
    
    do {
      try audioSession.setActive(
        false, options: .notifyOthersOnDeactivation)
    } catch {
      print("Failed to deactivate audio session: \(error)")
    }
    
    DispatchQueue.main.async {
      self.isRecording = false
      self.isProcessing = true
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
      self?.finishTranscribing()
    }
  }
  
  // Play the voice record
  func playRecording() {
    guard let audioFileURL = audioFileURL else { return }
    
    do {
      try audioSession.setCategory(.playback, mode: .default)
      try audioSession.setActive(true)
      
      audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
      audioPlayer?.delegate = self
      audioPlayer?.play()
      isPlaying = true
    } catch {
      print("Playback error: \(error.localizedDescription)")
    }
  }
  
  func stopPlayback() {
    audioPlayer?.stop()
    isPlaying = false
    
    do {
      try audioSession.setActive(
        false, options: .notifyOthersOnDeactivation)
    } catch {
      print("Failed to deactivate audio session: \(error)")
    }
  }
  
  /// Save the recording
	func saveRecording(name: String) {
		guard let audioFileURL = audioFileURL,
			  let userId = Auth.auth().currentUser?.uid
		else { return }

		/// Ensure the audio player is initialized before accessing duration
		if let audioPlayer = try? AVAudioPlayer(contentsOf: audioFileURL) {
			audioPlayer.prepareToPlay()

			let recordId = UUID().uuidString
			let storageRef = storage.reference().child("recordings/\(userId)/\(recordId).m4a")
			
			storageRef.putFile(from: audioFileURL, metadata: nil) { metadata, error in
				if let error = error {
					print("Error uploading file: \(error.localizedDescription)")
					return
				}
				
				storageRef.downloadURL { url, error in
					guard let downloadURL = url else {
						print("Error getting download URL: \(error?.localizedDescription ?? "Unknown error")")
						return
					}

					// Access the duration after audioPlayer is ready
					let metadata = RecordingMetadata(
						id: recordId,
						name: name,
						timestamp: Date(),
						duration: audioPlayer.duration,
						wordsPerMinute: self.wordsPerMinute,
						speechSpeed: self.speed,
						transcript: self.transcript,
						storageUrl: downloadURL.absoluteString
					)

					self.saveMetadataToFirestore(metadata: metadata)

					DispatchQueue.main.async {
						print("Size of recordings before updated view model \(self.recordings.count)")
						self.recordings.append(metadata)
						self.recordings = self.recordings.sorted(by: {$0.timestamp > $1.timestamp})
						print("Size of recordings after updated view model \(self.recordings.count)")
					}
				}
			}
		} else {
			print("Error initializing audio player")
		}
	}
  
  /// Save the metadata with recording to Firebase
  private func saveMetadataToFirestore(metadata: RecordingMetadata) {
    guard let userId = Auth.auth().currentUser?.uid else { return }
    
    do {
      try db.collection("users").document(userId).collection("recordings")
        .document(metadata.id).setData(from: metadata)

    } catch let error {
      print("Error saving metadata: \(error.localizedDescription)")
    }
  }
  
  func loadRecordings() {
    guard let userId = Auth.auth().currentUser?.uid else { return }
    
    db.collection("users").document(userId).collection("recordings")
      .getDocuments { querySnapshot, error in
        if let error = error {
          print(
            "Error getting documents: \(error.localizedDescription)"
          )
          return
        }
        
        self.recordings =
        querySnapshot?.documents.compactMap { document in
          try? document.data(as: RecordingMetadata.self)
        } ?? []
        self.recordings = self.recordings.sorted(by: {$0.timestamp > $1.timestamp})
      }
  }
  
  /// Delete the recording
  func deleteRecording(id: String) {
    guard let userId = Auth.auth().currentUser?.uid else { return }
    
    // Delete from Firestore
    db.collection("users").document(userId).collection("recordings")
      .document(id).delete { error in
        if let error = error {
          print(
            "Error deleting document: \(error.localizedDescription)"
          )
        } else {
          // Delete from Storage
          if let recording = self.recordings.first(where: {
            $0.id == id
          }),
             let storageUrl = URL(string: recording.storageUrl)
          {
            let storageRef = self.storage.reference(
              forURL: storageUrl.absoluteString)
            storageRef.delete { error in
              if let error = error {
                print(
                  "Error deleting file: \(error.localizedDescription)"
                )
              } else {
                self.loadRecordings()
              }
            }
          }
        }
      }
  }
  
  /// Finish the transcript after loading
  private func finishTranscribing() {
    reset()
    DispatchQueue.main.async {
      self.isProcessing = false
      self.canAnalyze = true
      self.isFinalizing = false
      self.isPlaybackAvailable = true
    }
  }
  
  private func speak(_ message: String) {
    transcript = message
  }
}

extension SpeechRecognizer: AVAudioPlayerDelegate {
  func audioPlayerDidFinishPlaying(
    _ player: AVAudioPlayer, successfully flag: Bool
  ) {
    DispatchQueue.main.async {
      self.isPlaying = false
    }
  }
}

extension SFSpeechRecognizer {
  static func hasAuthorizationToRecognize() async -> Bool {
    await withCheckedContinuation { continuation in
      requestAuthorization { status in
        continuation.resume(returning: status == .authorized)
      }
    }
  }
}

extension AVAudioSession {
  func hasPermissionToRecord() async -> Bool {
    await withCheckedContinuation { continuation in
      requestRecordPermission { authorized in
        continuation.resume(returning: authorized)
      }
    }
  }
}

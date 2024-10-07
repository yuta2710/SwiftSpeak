//
//  SpeechRecognizer.swift
//  Scrumdinger
//
//  Created by Nguyen Phuc Loi on 02/10/2024.
//

import AVFoundation
import Foundation
import Speech
import SwiftUI

enum SpeechSpeed: String {
	case Slow = "Slow"
	case Normal = "Normal"
	case Fast = "Fast"
	case VeryFast = "Very Fast"
	case Unclear = "Unclear"
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
			case .notAuthorizedToRecognize: return "Not authorized to recognize speech"
			case .notPermittedToRecord: return "Not permitted to record audio"
			case .recognizerIsUnavailable: return "Recognizer is unavailable"
			case .transcriptionFailed(let details): return "Transcription failed: \(details)"
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

	private var audioEngine: AVAudioEngine?
	private var request: SFSpeechAudioBufferRecognitionRequest?
	private var task: SFSpeechRecognitionTask?
	private let recognizer: SFSpeechRecognizer?
	
	private var startTime: Date?
	private var wordCount: Int = 0
	private var isFinalizing: Bool = false
	private var lastTranscriptUpdate: Date?
	private let unclearSpeechThreshold: TimeInterval = 3.0 // 3 seconds

	private var audioRecorder: AVAudioRecorder?
	private var audioPlayer: AVAudioPlayer?
	private var audioFileURL: URL?
	
	override init() {
		recognizer = SFSpeechRecognizer()
		super.init()
		
		Task(priority: .background) {
			do {
				guard recognizer != nil else {
					throw RecognizerError.nilRecognizer
				}
				guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
					throw RecognizerError.notAuthorizedToRecognize
				}
				guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
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
    
	func reset() {
		task?.cancel()
		audioEngine?.stop()
		audioEngine = nil
		request = nil
		task = nil
		audioRecorder?.stop()
		audioPlayer?.stop()
		isPlaying = false
	}
    
    /**
     Begin transcribing audio.
     
     Creates a `SFSpeechRecognitionTask` that transcribes speech to text until you call `stopTranscribing()`.
     The resulting transcription is continuously written to the published `transcript` property.
     */
    
    /// Begins transcribing audio and analyzing speech speed
    func transcribe() {
        DispatchQueue(label: "Speech Recognizer Queue", qos: .background).async { [weak self] in
            guard let self = self, let recognizer = self.recognizer, recognizer.isAvailable else {
                self?.speakError(RecognizerError.recognizerIsUnavailable)
                return
            }
            
            do {
                let (audioEngine, request) = try Self.prepareEngine()
                self.audioEngine = audioEngine
                self.request = request
                self.startTime = Date()
                self.wordCount = 0
                self.isFinalizing = false
                self.lastTranscriptUpdate = Date()
                
                // Set up audio recording
				let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
				self.audioFileURL = documentsPath.appendingPathComponent("speechRecording.m4a")
				let settings = [
					AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
					AVSampleRateKey: 44100,
					AVNumberOfChannelsKey: 2,
					AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
				]
				self.audioRecorder = try AVAudioRecorder(url: self.audioFileURL!, settings: settings)
				self.audioRecorder?.record()
                
                self.task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                    guard let self = self else { return }
                    
                    if let result = result {
                        self.updateTranscript(result.bestTranscription)
                        if result.isFinal {
                            self.finishTranscribing()
                        }
                    }
                    
                    if let error = error {
                        if !self.isFinalizing {
                            print("Recognition error: \(error.localizedDescription)")
                            // Only treat as an error if we haven't received any transcription
                            if self.transcript.isEmpty {
                                self.speakError(RecognizerError.transcriptionFailed(error.localizedDescription))
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
    

    
    /// Function to analyze the text WPM
    func analyzeSpeedAndWPM() {
        guard let startTime = self.startTime else { return }
        
        let elapsedTimeInMinutes = Date().timeIntervalSince(startTime) / 60.0
        let wordsPerMinute = max(0, Int(Double(self.wordCount) / elapsedTimeInMinutes))
        
        DispatchQueue.main.async {
            self.wordsPerMinute = wordsPerMinute
            self.speed = self.categorizeSpeechSpeed(wordsPerMinute: wordsPerMinute)
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
           Date().timeIntervalSince(lastUpdate) >= unclearSpeechThreshold {
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

    private static func prepareEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let audioEngine = AVAudioEngine()
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
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
        DispatchQueue.main.async {
            self.isRecording = false
            self.isProcessing = true
        }
        
        // Allow some time for final processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.finishTranscribing()
        }
    }
    
    // Play the voice record
	func playRecording() {
		guard let audioFileURL = audioFileURL else { return }
		
		do {
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
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
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

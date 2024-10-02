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
    case Unclear = "Unclear"
}

/// A helper for transcribing speech to text using SFSpeechRecognizer and AVAudioEngine.
class SpeechRecognizer: ObservableObject {
    enum RecognizerError: Error {
        case nilRecognizer
        case notAuthorizedToRecognize
        case notPermittedToRecord
        case recognizerIsUnavailable
        
        var message: String {
            switch self {
            case .nilRecognizer: return "Can't initialize speech recognizer"
            case .notAuthorizedToRecognize: return "Not authorized to recognize speech"
            case .notPermittedToRecord: return "Not permitted to record audio"
            case .recognizerIsUnavailable: return "Recognizer is unavailable"
            }
        }
    }
    
    @Published var transcript: String = ""
    @Published var speed: SpeechSpeed = .Normal
    @Published var wordsPerMinute: Int = 0
    @Published var showUnclearSpeechAlert: Bool = false
    @Published var isRecording: Bool = false
    @Published var canAnalyze: Bool = false

    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?
    
    private var startTime: Date?
    private var wordCount: Int = 0
    private var lastTranscriptUpdate: Date?
    private let unclearSpeechThreshold: TimeInterval = 3.0 // 3 seconds
    
    init() {
        recognizer = SFSpeechRecognizer()
        
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
                self.lastTranscriptUpdate = Date()
                
                self.task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                    guard let self = self else { return }
                    
                    if let result = result {
                        DispatchQueue.main.async {
                            self.updateTranscript(result.bestTranscription)
                        }
                    }
                    
                    if error != nil || result?.isFinal == true {
                        audioEngine.stop()
                        audioEngine.inputNode.removeTap(onBus: 0)
                        self.isRecording = false
                        self.canAnalyze = true
                    }
                }
                
                self.isRecording = true
                self.canAnalyze = false
            } catch {
                self.reset()
                self.speakError(error)
            }
        }
    }
    
//    /// Analyzes the speed of speech based on the transcription
//    private func analyzeSpeed(transcription: SFTranscription) {
//        guard let startTime = self.startTime else { return }
//
//        let currentWordCount = transcription.segments.count
//        let elapsedTimeInMinutes = Date().timeIntervalSince(startTime) / 60.0
//
//        // Only update if we have new words
//        if currentWordCount > self.wordCount {
//            self.wordCount = currentWordCount
//            
//            // Calculate words per minute
//            let wordsPerMinute = Int(Double(self.wordCount) / elapsedTimeInMinutes)
//
//            DispatchQueue.main.async {
//                self.wordsPerMinute = wordsPerMinute
//                self.speed = self.categorizeSpeechSpeed(wordsPerMinute: wordsPerMinute)
//                
//                // Check for unclear speech
//                if self.speed == .Unclear {
//                    self.handleUnclearSpeech()
//                } else {
//                    self.lastClearSpeechTime = Date()
//                }
//            }
//        }
//    }
    
    /// Function to analyze the text WPM
    func analyzeSpeedAndWPM() {
        guard let startTime = self.startTime else { return }
        
        let elapsedTimeInMinutes = Date().timeIntervalSince(startTime) / 60.0
        let wordsPerMinute = Int(Double(self.wordCount) / elapsedTimeInMinutes)
        
        DispatchQueue.main.async {
            self.wordsPerMinute = wordsPerMinute
            self.speed = self.categorizeSpeechSpeed(wordsPerMinute: wordsPerMinute)
        }
    }
    /// Update transcript to get whole text in one session
    private func updateTranscript(_ transcription: SFTranscription) {
        self.transcript = transcription.formattedString
        let newWordCount = transcription.segments.count
        
        if newWordCount > self.wordCount {
            self.wordCount = newWordCount
            self.lastTranscriptUpdate = Date()
        } else {
            self.checkForUnclearSpeech()
        }
    }
    
    /// Check for Optimus Prime oe oe oe
    private func checkForUnclearSpeech() {
        if let lastUpdate = lastTranscriptUpdate,
           Date().timeIntervalSince(lastUpdate) >= unclearSpeechThreshold {
            self.showUnclearSpeechAlert = true
        }
    }
    
    /// Categorizes speech speed based on words per minute
    private func categorizeSpeechSpeed(wordsPerMinute: Int) -> SpeechSpeed {
        switch wordsPerMinute {
        case 1...109:
            return .Slow
        case 110...150:
            return .Normal
        case 151...250:
            return .Fast
        default:
            return .Unclear
        }
    }
    
//    /// Handles detection of unclear speech
//    private func handleUnclearSpeech() {
//        if let lastClearTime = lastClearSpeechTime,
//           Date().timeIntervalSince(lastClearTime) >= unclearSpeechThreshold {
//            showUnclearSpeechAlert = true
//        }
//    }
    
//    private func analyzeDetailsOfSpeed(transcription: SFTranscription) {
//        let words = transcription.segments
//        guard let firstWord = words.first, let lastWord = words.last else {
//            return
//        }
//        
//        // Calculate the total duration of the speech
//        let totalTime = lastWord.timestamp - firstWord.timestamp
//        let wordsPerSecond = Double(words.count) / totalTime
//        
//        let speedCategory: String
//        
//        if wordsPerSecond > 5.0 {
//            speedCategory = SpeedType.Fast.value
////            print("Word per second of fast = ", wordsPerSecond)
//        } else if wordsPerSecond > 2 {
//            speedCategory = SpeedType.Normal.value
////            print("Word per second of normal = ", wordsPerSecond)
//        } else {
//            speedCategory = SpeedType.Slow.value
////            print("Word per second of slow = ", wordsPerSecond)
//        }
//        
//        DispatchQueue.main.async {
//            self.speed = speedCategory
////            self.wordsPerSecond = wordsPerSecond
//        }
//    }
    
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
    
    /// Stops transcribing audio
    func stopTranscribing() {
        reset()
        isRecording = false
        canAnalyze = true
    }
    
    private func speak(_ message: String) {
        transcript = message
    }
    
    private func speakError(_ error: Error) {
        var errorMessage = ""
        if let error = error as? RecognizerError {
            errorMessage += error.message
        } else {
            errorMessage += error.localizedDescription
        }
        transcript = "<< \(errorMessage) >>"
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

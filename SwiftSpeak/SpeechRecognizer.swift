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
    
    var value: String {
        switch self {
        case .Slow:
            return "Slow"
        case .Normal:
            return "Normal"
        case .Fast:
            return "Fast"
        case .Unclear:
            return "Unclear"
        }
    }
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
    @Published var wordsPerMinute: Double = 0.0
    @Published var showUnclearSpeechAlert: Bool = false

    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?
    
    private var lastClearSpeechTime: Date?
    private let unclearSpeechThreshold: TimeInterval = 5.0 // 5 seconds
    
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
                self.lastClearSpeechTime = Date()
                
                self.task = recognizer.recognitionTask(with: request) { result, error in
                    let receivedFinalResult = result?.isFinal ?? false
                    let receivedError = error != nil
                    
                    if receivedFinalResult || receivedError {
                        audioEngine.stop()
                        audioEngine.inputNode.removeTap(onBus: 0)
                    }
                    
                    if let result = result {
                        self.analyzeSpeed(transcription: result.bestTranscription)
                        self.speak(result.bestTranscription.formattedString)
                    }
                }
            } catch {
                self.reset()
                self.speakError(error)
            }
        }
    }
    
    /// Analyzes the speed of speech based on the transcription
    private func analyzeSpeed(transcription: SFTranscription) {
        let words = transcription.segments
        guard let firstWord = words.first, let lastWord = words.last else {
            return
        }

        // Calculate words per minute
        let totalTimeInMinutes = (lastWord.timestamp - firstWord.timestamp) / 60.0
        let wordsPerMinute = Double(words.count) / totalTimeInMinutes

        DispatchQueue.main.async {
            self.wordsPerMinute = wordsPerMinute
            self.speed = self.categorizeSpeechSpeed(wordsPerMinute: wordsPerMinute)
            
            // Check for unclear speech
            if self.speed == .Unclear {
                self.handleUnclearSpeech()
            } else {
                self.lastClearSpeechTime = Date()
            }
        }
    }
    
    
    /// Categorizes speech speed based on words per minute
    private func categorizeSpeechSpeed(wordsPerMinute: Double) -> SpeechSpeed {
        switch wordsPerMinute {
        case ...110:
            return .Slow
        case 110...150:
            return .Normal
        case 150...:
            return .Fast
        default:
            return .Unclear
        }
    }
    
    /// Handles detection of unclear speech
    private func handleUnclearSpeech() {
        if let lastClearTime = lastClearSpeechTime,
           Date().timeIntervalSince(lastClearTime) >= unclearSpeechThreshold {
            showUnclearSpeechAlert = true
        }
    }
    
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
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            request.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
        
        return (audioEngine, request)
    }
    
    /// Stop transcribing audio.
    func stopTranscribing() {
        reset()
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

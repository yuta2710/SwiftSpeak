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

enum SpeedType {
    case Slow
    case Normal
    case Fast
    
    var value: String {
        switch self {
        case .Slow:
            return "Slow"
        case .Normal:
            return "Normal"
        case .Fast:
            return "Fast"
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
    @Published var speed: String = ""
    @Published var wordsPerSecond: Double = 0.0
    @Published var wordsPerMinute: Double = 0.0
    
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?
    private var startTime: DispatchTime?
    
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
        startTime = DispatchTime.now()
        
        DispatchQueue(label: "Speech Recognizer Queue", qos: .background).async { [weak self] in
            guard let self = self, let recognizer = self.recognizer, recognizer.isAvailable else {
                self?.speakError(RecognizerError.recognizerIsUnavailable)
                return
            }
            
            do {
                let (audioEngine, request) = try Self.prepareEngine()
                self.audioEngine = audioEngine
                self.request = request
                
                self.task = recognizer.recognitionTask(with: request) { result, error in
                    let receivedFinalResult = result?.isFinal ?? false
                    let receivedError = error != nil // != nil mean there's error (true)
                    
                    if receivedFinalResult || receivedError {
                        audioEngine.stop()
                        audioEngine.inputNode.removeTap(onBus: 0)
                    }
                    
                    if let result = result {
                        DispatchQueue.main.async {
                            self.speak(result.bestTranscription.formattedString)
                            self.analyzeDetailsOfSpeed(text: self.transcript)
                        }
                    }
                }
            } catch {
                self.reset()
                self.speakError(error)
            }
        }
    }
    
    private func analyzeDetailsOfSpeed(text: String) {
        //        let words = transcription.segments
        var lengthOfText = Array(text).count
        
        print("Length of text \(lengthOfText)")
        
        guard let startTime = startTime else { return }
        
        // Get the current time to calculate the duration
        let endTime = DispatchTime.now()
        let elapsedTime = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
        
        // Split the transcript into words and count them
        let words = text.split(separator: " ").count
        
        // Calculate words per minute
        let wordsPerMinute = (Double(words) / elapsedTime) * 60
        self.wordsPerMinute = wordsPerMinute
        
        let speedCategory: String = ""
        
        
        // Determine the speed type based on WPM
        if wordsPerMinute < 45 {
            self.speed = SpeedType.Slow.value
        }
        
        if wordsPerMinute > 50 && wordsPerMinute < 80  {
            self.speed = SpeedType.Normal.value
        }
        
        if wordsPerMinute > 100 {
            self.speed = SpeedType.Fast.value
        }
        
        print(self.wordsPerMinute)
        
        // Log the result
        print("WPM: \(wordsPerMinute), Speed: \(self.speed)")
        //        guard let firstWord = words.first, let lastWord = words.last else {
        //            return
        //        }
        //
        //        // Calculate the total duration of the speech
        //        let totalTimeInMinutes = (lastWord.timestamp - firstWord.timestamp) / 60.0
        //
        //        // Calculate words per minute
        //        let wordsPerMinute = Double(words.count) / totalTimeInMinutes
        //
        //        print("Words per minute = ", wordsPerMinute)
        //
        //        let speedCategory: String
        //        if wordsPerMinute < 16000.0 && wordsPerMinute > 12000.0 {
        //            speedCategory = "Fast"
        //        } else if wordsPerMinute < 900.0 {
        //            speedCategory = "Slow"
        //        } else {
        //            speedCategory = "Normal"
        //        }
        
//        DispatchQueue.main.async {
//            self.speed =
//        }
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

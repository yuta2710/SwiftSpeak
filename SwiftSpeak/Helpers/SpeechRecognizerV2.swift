//
//  SpeechRecognizerV2.swift
//  SwiftSpeak
//
//  Created by Nguyen Phuc Loi on 03/10/2024.
//

import Foundation
import FirebaseStorage
import AVFoundation
import lame

class SpeechRecognizerV2: NSObject, ObservableObject, AVAudioRecorderDelegate {
    var audioRecorder: AVAudioRecorder!
    let converter = AudioConverter()
    
    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [])
            try session.setActive(true)
            let url = getDocumentsDirectory().appendingPathComponent("recording.wav")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            print("Url is \(url)")
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
        } catch let error {
            print("Error recording audio: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder.stop()
        
        let wavFilePath = audioRecorder.url.path
        let mp3FilePath = getDocumentsDirectory().appendingPathComponent("recording.mp3").path
        
        // Convert to MP3 after stopping the recording
        if converter.convertWAVtoMP3(wavFilePath: wavFilePath, mp3FilePath: mp3FilePath) {
            print("Conversion to MP3 successful. MP3 file at: \(mp3FilePath)")
        } else {
            print("Conversion failed.")
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}

class AudioUploader {
    func uploadAudioFileToFirebase(audioFileURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let storageRef = Storage.storage().reference().child("audio/\(UUID().uuidString).mp3")
        
        storageRef.putFile(from: audioFileURL, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
            } else {
                storageRef.downloadURL { url, error in
                    if let error = error {
                        completion(.failure(error))
                    } else if let downloadURL = url {
                        completion(.success(downloadURL))
                    }
                }
            }
        }
    }
}



//import AVFoundation

class AudioConverter {
    
    func convertWAVtoMP3(wavFilePath: String, mp3FilePath: String) -> Bool {
        let wavFile = fopen(wavFilePath, "rb")
        let mp3File = fopen(mp3FilePath, "wb")
        
        guard wavFile != nil, mp3File != nil else {
            print("Failed to open files")
            return false
        }

        let PCM_SIZE: Int32 = 8192
        let MP3_SIZE: Int32 = 8192
        
        let pcmBuffer = UnsafeMutablePointer<Int16>.allocate(capacity: Int(PCM_SIZE * 2))
        let mp3Buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(MP3_SIZE))

        let lame = lame_init()
        lame_set_in_samplerate(lame, 44100)
        lame_set_VBR(lame, vbr_default)
        lame_init_params(lame)

        var read: Int32 = 0
        var write: Int32 = 0
        
        repeat {
            read = Int32(fread(pcmBuffer, 2 * MemoryLayout<Int16>.size, Int(PCM_SIZE), wavFile))
            if read == 0 {
                write = lame_encode_flush(lame, mp3Buffer, MP3_SIZE)
            } else {
                write = lame_encode_buffer_interleaved(lame, pcmBuffer, read / 2, mp3Buffer, MP3_SIZE)
            }
            fwrite(mp3Buffer, Int(write), 1, mp3File)
        } while read != 0

        lame_close(lame)
        fclose(mp3File)
        fclose(wavFile)
        pcmBuffer.deallocate()
        mp3Buffer.deallocate()
        
        print("MP3 conversion completed.")
        return true
    }
}

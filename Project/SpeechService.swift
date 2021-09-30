//
//  SpeechService.swift
//  Project
//
//  Created by Dorian Bizgan on 6/30/20.
//  Copyright © 2020 Dorian Bizgan. All rights reserved.
//

import UIKit
import AVFoundation

enum VoiceType: String {
    case undefined
    case americanFemale = "en-US-Wavenet-C"
    case americanMale = "en-US-Wavenet-A"
    case britishFemale = "en-GB-Wavenet-A"
    case britishMale = "en-GB-Wavenet-D"
    case australianFemale = "en-AU-Wavenet-A"
    case australianMale = "en-AU-Wavenet-B"
}

// API Information
let ttsAPIUrl = "https://texttospeech.googleapis.com/v1beta1/text:synthesize"
let APIKey = "AIzaSyAH5Q58NaUypifDUcBdN2-WEo_rTr30aT8"


class SpeechService: NSObject, AVAudioPlayerDelegate {

    static let shared = SpeechService()
    private(set) var busy: Bool = false
    
    private var player: AVAudioPlayer?
    private var completionHandler: (() -> Void)?
    
    var curAudioData = Data();
    
    func speak(text: String, voiceType: VoiceType = .americanFemale, completion: @escaping () -> Void) {
        guard !self.busy else {
            print("Speech Service busy!")
            return
        }
        
        self.busy = true
        
        DispatchQueue.global(qos: .background).async {
            let postData = self.buildPostData(text: text, voiceType: voiceType)
            let headers = ["X-Goog-Api-Key": APIKey, "Content-Type": "application/json; charset=utf-8"]
            let response = self.makePOSTRequest(url: ttsAPIUrl, postData: postData, headers: headers)

            // Get the `audioContent` (as a base64 encoded string) from the response.
            guard let audioContent = response["audioContent"] as? String else {
                print("Invalid response: \(response)")
                self.busy = false
                DispatchQueue.main.async {
                    completion()
                }
                return
            }
            
            // Decode the base64 string into a Data object
            guard let audioData = Data(base64Encoded: audioContent) else {
                self.busy = false
                DispatchQueue.main.async {
                    completion()
                }
                return
            }
            
            DispatchQueue.main.async {
                
                do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowAirPlay])
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch {
                    print(error)
                }
                self.completionHandler = completion
                self.player = try! AVAudioPlayer(data: audioData)
                self.curAudioData = audioData
                
                self.player?.delegate = self
                self.player!.play()
            }
            

            }
        }
    
    func returnAudioData() -> Data {
        return self.curAudioData
    }
    
    func pause() {
        if self.player != nil {
        self.player!.pause()
        }
    }
    
    func play() {
        self.player!.play()
    }
    
    func stop() {
        if self.player != nil {
        self.player!.stop()
        audioPlayerDidFinishPlaying(self.player!, successfully: false)
        }
    }
    
    private func buildPostData(text: String, voiceType: VoiceType) -> Data {
        
        var voiceParams: [String: Any] = [
            // All available voices here: https://cloud.google.com/text-to-speech/docs/voices
            "languageCode": "en-US"
        ]
        
        if voiceType != .undefined {
            voiceParams["name"] = voiceType.rawValue
        }
        //let rates = [0.25, 0.5, 1.0, 1.5, 2.0]
        //let speedIndex = UserDefaults.value(forKey: "speedPreference")
        //print("\(speedIndex)")
        //let speedPreference = rates[2]
        
        let params: [String: Any] = [
            "input": [
                "text": text
            ],
            "voice": voiceParams,
            "audioConfig": [
                // All available formats here: https://cloud.google.com/text-to-speech/docs/reference/rest/v1beta1/text/synthesize#audioencoding
                "audioEncoding": "LINEAR16",
                //"speakingRate": speedPreference
            ]
        ]

        // Convert the Dictionary to Data
        let data = try! JSONSerialization.data(withJSONObject: params)
        return data
    }
    
    // Just a function that makes a POST request.
    private func makePOSTRequest(url: String, postData: Data, headers: [String: String] = [:]) -> [String: AnyObject] {
        var dict: [String: AnyObject] = [:]
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.httpBody = postData

        for header in headers {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        // Using semaphore to make request synchronous
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] {
                dict = json
            }
            
            semaphore.signal()
        }
        
        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        return dict
    }
    
    
    // Implement AVAudioPlayerDelegate "did finish" callback to cleanup and notify listener of completion.
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player?.delegate = nil
        self.player = nil
        self.busy = false
        
        self.completionHandler!()
        self.completionHandler = nil
    }
}


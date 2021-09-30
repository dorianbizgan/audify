//
//  DocumentViewController.swift
//  Project
//
//  Created by Dorian Bizgan on 6/29/20.
//  Copyright © 2020 Dorian Bizgan. All rights reserved.
//

import UIKit
import Vision
import VisionKit
import AVFoundation

class DocumentViewController: UIViewController, VNDocumentCameraViewControllerDelegate{

    

    // Views
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    // Buttons
    @IBOutlet weak var scanDocumentButton: UIButton!
    @IBOutlet weak var audioPlayPauseIcon: UIImageView!
    @IBOutlet weak var speakButton: UIButton!
    
    @IBOutlet weak var titleLabel: UITextView!
    
    // Elements originating from DocumentsViewController
    var delegate: UIViewController!
    var textFromPrevious:String = ""
    var imagesFromPrevious:String = ""
    var documentIndex:Int = 0
    var audioData = Data()
    var newScan = Bool()
    var documentTitle = String()
    
    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    var images = [UIImage]()
    
    // - Ensures that a Audio Player exists
    // - Boolean to check for difference
    // in text being spoken and what's in the textField
    var currentTextBeingSpoken = ""
    var audioPlayerActive = false
    private let textRecognitionWorkQueue = DispatchQueue(label: "MyVisionScannerQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.isEditable = true
        textView.text = textFromPrevious
        
        titleLabel.text = documentTitle
        textView.layer.cornerRadius = 14
        
        scanDocumentButton.layer.cornerRadius = 14
        speakButton.layer.cornerRadius = 14
        audioPlayPauseIcon.layer.zPosition = 1
        
        scrollView.layer.zPosition = 1
        scrollView.alpha = 0
        imageView.alpha = 0
        textView.contentInset = UIEdgeInsets(top:10,left:10,bottom:10,right:10)
        // dismiss keyboard when tapping outside field being edited
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print(newScan)
        if newScan == true {
            self.scanDocumentButton.sendActions(for: .touchUpInside)
            newScan = false
        }
        setupVision()
    }
    

    @IBAction func btnTakePicture(_ sender: Any) {
        print("take picture button pressed")
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = self
        present(scannerViewController, animated: true)
    }
    
    private func setupVision() {
        textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            var detectedText = ""
            for observation in observations {
                let maximumCandidates = 1
                guard let topCandidate = observation.topCandidates(maximumCandidates).first else { return }
                
    
                print(topCandidate.string)
                if topCandidate.string.last == "-" {
                    detectedText += topCandidate.string.dropLast()
                }
                else {
                detectedText += topCandidate.string + " "
                // detectedText += " "
                }
            }
            
            DispatchQueue.main.async {
                self.textView.text += detectedText
                self.titleLabel.text = "Untitled"
                self.textView.flashScrollIndicators()

            }
        }

        textRecognitionRequest.recognitionLevel = .accurate     // Speed of text detection - Accurate is slower than .fast
        //textRecognitionRequest.minimumTextHeight = 0.05          // Relative height of text ignored
        textRecognitionRequest.usesLanguageCorrection = true    // Corrects for scanning errors using autocorrect
        textRecognitionRequest.recognitionLanguages = ["en-US"] // Will be expecting English words
        

    }
    
    private func processImage(_ image: UIImage, i:Int) {
        
        // Resets the speak button to visually signify new scan
        self.speakButton.setTitle("Speak", for: .normal)
        self.audioPlayPauseIcon.image = UIImage(systemName: "playpause")

        let imageView = UIImageView()
        imageView.image = images[i]
        let xPosition = UIScreen.main.bounds.width * CGFloat(i)
        imageView.frame = CGRect(x: xPosition, y: 0, width: scrollView.frame.width, height: scrollView.frame.height)
        imageView.contentMode = .scaleAspectFit
        
        scrollView.contentSize.width = scrollView.frame.width * CGFloat(i + 1)
        scrollView.addSubview(imageView)
        
        
        recognizeTextInImage(image)
    }
    
    private func recognizeTextInImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        //textView.text = "" // resetting text - disable to process multiple images
        textRecognitionWorkQueue.async {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try requestHandler.perform([self.textRecognitionRequest])
            } catch {
                print(error)
            }
        }
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        
        //textView.text = "" // reset text view text for a new scan
        images.removeAll(keepingCapacity: false) // reset images list
        for subview in self.scrollView.subviews {
            subview.removeFromSuperview()
        }
        
        guard scan.pageCount >= 1 else {
            controller.dismiss(animated: true)
            return
        }
        
        for pageNumber in 0..<scan.pageCount {
            let originalImage = scan.imageOfPage(at: pageNumber)
            let newImage = compressedImage(originalImage)
            images.append(newImage)
            processImage(newImage,i: pageNumber)
        }
        controller.dismiss(animated: true)
        
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print(error)
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }

    func compressedImage(_ originalImage: UIImage) -> UIImage {
        guard let imageData = originalImage.jpegData(compressionQuality: 1),
            let reloadedImage = UIImage(data: imageData) else {
                return originalImage
        }
        return reloadedImage
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        SpeechService.shared.stop()
        if textView.text != textFromPrevious || titleLabel.text != documentTitle {
            if textView.text == "" {
                return
            }
            if textFromPrevious == "" {
                let otherVC = delegate as? DocumentUpdater
                otherVC?.addDocument(text: textView.text, documentTitle: titleLabel.text ?? "Untitled")
            }
            else if titleLabel.text != documentTitle {
                let otherVC = delegate as? DocumentUpdater
                otherVC?.updateDocument(text: textView.text, documentTitle: titleLabel.text, documentIndex: documentIndex)
            }
            else {
                let otherVC = delegate as? DocumentUpdater
                otherVC?.updateDocument(text: textView.text, documentTitle: documentTitle, documentIndex: documentIndex)
            }
        
        }
        
    }
    
    // action for when Speak Button is pressed
    @IBAction func didPressSpeakButton(_ sender: Any) {
        
        // Do this if a Audio Player exists
        if self.audioPlayerActive == true {
        if textView.text == self.currentTextBeingSpoken {
            if speakButton.currentTitle == "Playing..." {
                SpeechService.shared.pause()
                self.audioPlayPauseIcon.image = UIImage(systemName: "play")
                self.speakButton.setTitle("Paused", for: .normal)
                return
            }
            
            if speakButton.currentTitle == "Paused"
            {
                SpeechService.shared.play()
                self.audioPlayPauseIcon.image = UIImage(systemName: "pause")
                self.speakButton.setTitle("Playing...", for: .normal)
                return
            }
            }
            
        //  Stop the audio player if the textView text is different from what is currently queued to play
        else {
            
            // Kills previous player if one exists to create a new Audio Player that takes the new text into account
            SpeechService.shared.stop()
            self.audioPlayerActive = false
            }
            
        }
    

        speakButton.setTitle("Playing...", for: .normal)

        var voiceType: VoiceType = .undefined
        
        let categorys = ["American", "British", "Australian"]
        let genders = ["Male","Female"]
        let defaults = UserDefaults.standard
        
        // create voice instance using user preferences
        let voiceCategoryPreference = defaults.integer(forKey: "voiceCategoryPreference")
        let voiceGenderPreference = defaults.integer(forKey: "voiceGenderPreference")
        
        let category = categorys[voiceCategoryPreference]
        let gender = genders[voiceGenderPreference]
        //let gender = voiceGenderControl.titleForSegment(at: voiceGenderControl.selectedSegmentIndex)
        if category == "American" && gender == "Female" {
            voiceType = .americanFemale
        }
        else if category == "American" && gender == "Male" {
            voiceType = .americanMale
        }
        else if category == "British" && gender == "Female" {
            voiceType = .britishFemale
        }
        else if category == "British" && gender == "Male" {
            voiceType = .britishMale
        }
        else if category == "Australian" && gender == "Female" {
            voiceType = .australianFemale
        }
        else if category == "Australian" && gender == "Male" {
            voiceType = .australianMale
        }
            
        // set value that determines if a player exists to true
        // speaks value of the current text field
        self.audioPlayerActive = true
        
        self.currentTextBeingSpoken = self.textView.text
        self.audioData = SpeechService.shared.curAudioData
        self.audioPlayPauseIcon.image = UIImage(systemName: "pause")
        SpeechService.shared.speak(text: textView.text, voiceType: voiceType) {
            self.speakButton.setTitle("Speak", for: .normal)
            self.audioPlayPauseIcon.image = UIImage(systemName: "playpause")
            self.speakButton.isEnabled = true
            self.speakButton.alpha = 1
        }
    }
}


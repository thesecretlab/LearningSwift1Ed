//
//  AudioAttachmentViewController.swift
//  Notes
//
//  Created by Jonathon Manning on 28/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import UIKit

import AVFoundation

class AudioAttachmentViewController: UIViewController, AttachmentViewer, AVAudioPlayerDelegate {
    
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    
    var attachmentFile : NSFileWrapper?
    var document : Document?
    
    var audioPlayer : AVAudioPlayer?
    var audioRecorder : AVAudioRecorder?
    
    override func viewDidLoad() {
        
        if attachmentFile != nil {
            prepareAudioPlayer()
        }
        
        updateButtonState()
    }
    
    func beginRecording () {
        // Try to use the same filename as before, if possible
        
        let fileName = self.attachmentFile?.preferredFilename ??
            "Recording \(Int(arc4random())).wav"
        
        let temporaryURL = NSURL(fileURLWithPath: NSTemporaryDirectory())
            .URLByAppendingPathComponent(fileName)
        
        do {
            self.audioRecorder = try AVAudioRecorder(URL: temporaryURL,
                settings: [:])
            
            self.audioRecorder?.record()
        } catch let error as NSError {
            NSLog("Failed to start recording: \(error)")
        }
        
        updateButtonState()
    }
    
    func stopRecording () {
        guard let recorder = self.audioRecorder else {
            return
        }
        recorder.stop()
        
        self.audioPlayer = try? AVAudioPlayer(contentsOfURL: recorder.url);
        
        updateButtonState()
    }
    
    func beginPlaying() {
        self.audioPlayer?.delegate = self
        self.audioPlayer?.play()
        
        updateButtonState()
    }
    
    func stopPlaying() {
        audioPlayer?.stop()
        updateButtonState()
    }
    
    override func viewWillDisappear(animated: Bool) {
        if let recorder = self.audioRecorder {
            
            // We have a recorder, which means we have a recording to attach
            do {
                attachmentFile = try self.document?.addAttachmentAtURL(recorder.url)
                
                prepareAudioPlayer()
                
            } catch let error as NSError {
                NSLog("Failed to attach recording: \(error)")
            }
        }
    }
    
    func prepareAudioPlayer()  {
        if let attachment = self.attachmentFile {
            
            self.document?.URLForAttachment(attachment, completion: { (url) -> Void in
                
                if let url = url {
                    do {
                        self.audioPlayer = try AVAudioPlayer(contentsOfURL: url)

                    } catch let error as NSError {
                        NSLog("Failed to prepare audio player: \(error)")
                    }
                }
                
                self.updateButtonState()
            })
        }
    }
    
    func updateButtonState() {
        if self.audioRecorder?.recording == true ||
            self.audioPlayer?.playing == true {

            // We are either recording or playing, so
            // show the stop button
            self.recordButton.hidden = true
            self.playButton.hidden = true
                
            self.stopButton.hidden = false
        } else if self.audioPlayer != nil {

            // We have a recording ready to go
            self.recordButton.hidden = true
            self.stopButton.hidden = true
            
            self.playButton.hidden = false
        } else {

            // We have no recording
            self.playButton.hidden = true
            self.stopButton.hidden = true
            
            self.recordButton.hidden = false
        }
        
    }
    
    @IBAction func recordTapped(sender: AnyObject) {
        beginRecording()
    }
    
    @IBAction func playTapped(sender: AnyObject) {
        beginPlaying()
    }
    
    @IBAction func stopTapped(sender: AnyObject) {
        stopRecording()
        stopPlaying()
    }
    
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
        
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        updateButtonState()
    }
    
}

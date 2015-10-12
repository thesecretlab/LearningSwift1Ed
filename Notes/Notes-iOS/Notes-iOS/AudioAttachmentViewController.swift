//
//  AudioAttachmentViewController.swift
//  Notes
//
//  Created by Jonathon Manning on 28/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import UIKit
// BEGIN import_avfoundation
import AVFoundation
// END import_avfoundation

// BEGIN audio_protocols
class AudioAttachmentViewController: UIViewController, AttachmentViewer,
    AVAudioPlayerDelegate
// END audio_protocols
{
    
    // BEGIN audio_button_outlets
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    // END audio_button_outlets
    
    // BEGIN audio_attachment_viewer
    var attachmentFile : NSFileWrapper?
    var document : Document?
    // END audio_attachment_viewer
    
    // BEGIN audio_properties
    var audioPlayer : AVAudioPlayer?
    var audioRecorder : AVAudioRecorder?
    // END audio_properties
    
	// BEGIN audio_view_did_load
    override func viewDidLoad() {
        
        if attachmentFile != nil {
            prepareAudioPlayer()
        }
        
        // Indicate to the system that we will be both recording audio,
        // and also playing back audio
        do {
            try AVAudioSession.sharedInstance()
                .setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch let error as NSError {
            print("Error preparing for recording! \(error)")
        }
        
        updateButtonState()
    }
	// END audio_view_did_load
    
	// BEGIN audio_begin_recording
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
	// END audio_begin_recording
    
	// BEGIN audio_stop_recording
    func stopRecording () {
        guard let recorder = self.audioRecorder else {
            return
        }
        recorder.stop()
        
        self.audioPlayer = try? AVAudioPlayer(contentsOfURL: recorder.url);
        
        updateButtonState()
    }
	// END audio_stop_recording

	// BEGIN audio_begin_playing
    func beginPlaying() {
        self.audioPlayer?.delegate = self
        self.audioPlayer?.play()
        
        updateButtonState()
    }
	// END audio_begin_playing

    // BEGIN audio_stop_playing
    func stopPlaying() {
        audioPlayer?.stop()
        updateButtonState()
    }
	// END audio_stop_playing
    
	// BEGIN audio_view_will_disappear
    override func viewWillDisappear(animated: Bool) {
        if let recorder = self.audioRecorder {
            
            // We have a recorder, which means we have a recording to attach
            do {
                attachmentFile =
                    try self.document?.addAttachmentAtURL(recorder.url)
                
                prepareAudioPlayer()
                
            } catch let error as NSError {
                NSLog("Failed to attach recording: \(error)")
            }
        }
    }
    // END audio_view_will_disappear
	
	// BEGIN audio_prepare_audio_player
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
	// END audio_prepare_audio_player
	
    // BEGIN audio_update_button_state
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
    // END audio_update_button_state
	
    // BEGIN audio_record_tapped
    @IBAction func recordTapped(sender: AnyObject) {
        beginRecording()
    }
    // END audio_record_tapped
    
	// BEGIN audio_play_tapped
    @IBAction func playTapped(sender: AnyObject) {
        beginPlaying()
    }
	// END audio_play_tapped
	
	// BEGIN audio_stop_tapped
    @IBAction func stopTapped(sender: AnyObject) {
        stopRecording()
        stopPlaying()
    }
	// END audio_stop_tapped
    
	// BEGIN audio_player_did_finish_playing
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        updateButtonState()
    }
    // END audio_player_did_finish_playing
}

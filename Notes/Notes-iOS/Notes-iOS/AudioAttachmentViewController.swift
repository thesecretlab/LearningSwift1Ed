//
//  AudioAttachmentViewController.swift
//  Notes
//
//  Created by Jonathon Manning on 28/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import UIKit

import AVFoundation

class AudioAttachmentViewController: UIViewController, AttachmentViewer {
    
    var attachmentFile : NSFileWrapper?
    var document : Document?
    
    var audioPlayer : AVAudioPlayer?
    var audioRecorder : AVAudioRecorder?
    
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
    }
    
    func stopRecording () {
        guard let recorder = self.audioRecorder else {
            return
        }
        recorder.stop()
    }
    
    override func viewWillDisappear(animated: Bool) {
        if let recorder = self.audioRecorder {
            
            // We have a recorder, which means we have a recording to attach
            do {
                try self.document?.addAttachmentAtURL(recorder.url)
            } catch let error as NSError {
                NSLog("Failed to attach recording: \(error)")
            }
        }
    }

}

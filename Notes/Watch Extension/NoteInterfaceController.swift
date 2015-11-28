//
//  NoteInterfaceController.swift
//  Notes
//
//  Created by Jon Manning on 3/11/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import WatchKit

class NoteInterfaceController: WKInterfaceController {

    @IBOutlet var noteContentLabel: WKInterfaceLabel!
    
    // BEGIN watch_note_awake_with_context
    override func awakeWithContext(context: AnyObject?) {
        
        // We've hopefully received an NSURL that points at a 
        // note on the iPhone we want to display!
        
        if let url = context as? NSURL {
            
            // First, clear the label - it might take a moment for
            // the text to appear.
            self.noteContentLabel.setText(nil)
            
            // BEGIN watch_note_awake_with_context_handoff
            let activityInfo = [WatchHandoffDocumentURL: url.absoluteString]
            
            // Note that this string needs to be the same as
            // the activity type you defined in the Info.plist for the iOS
            // and Mac apps
            updateUserActivity("au.com.secretlab.Notes.editing",
                userInfo: activityInfo, webpageURL: nil)
            // END watch_note_awake_with_context_handoff
            
            SessionManager.sharedSession.loadNote(url,
                completionHandler: { text, error -> Void in
                
                // BEGIN watch_note_awake_with_context_error_handling
                if let theError = error {
                    // We have an error! Present it, and add a button
                    // that closes this screen when tapped.
                    
                    let closeAction = WKAlertAction(title: "Close",
                        style: WKAlertActionStyle.Default, handler: { () -> Void in
                        self.popController()
                    })
                    
                    self.presentAlertControllerWithTitle("Error loading note",
                        message: theError.localizedDescription,
                        preferredStyle: WKAlertControllerStyle.Alert,
                        actions: [closeAction])
                    
                    return
                }
                // END watch_note_awake_with_context_error_handling
                    
                if let theText = text {
                    // We have the text! Display it.
                    self.noteContentLabel.setText(theText)
                }
            })
        }
        
    }
    // END watch_note_awake_with_context
}

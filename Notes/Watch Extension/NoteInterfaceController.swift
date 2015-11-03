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
    
    override func awakeWithContext(context: AnyObject?) {
        
        self.noteContentLabel.setText(nil)
        
        if let url = context as? NSURL {
            
            let activityInfo = [WatchHandoffDocumentURL: url.absoluteString]
            
            updateUserActivity("au.com.secretlab.Notes.editing", userInfo: activityInfo, webpageURL: nil)
            
            SessionManager.sharedSession.loadNote(url, completionHandler: { text, error -> Void in
                
                if let theError = error {
                    
                    let closeAction = WKAlertAction(title: "Close", style: WKAlertActionStyle.Default, handler: { () -> Void in
                        self.popController()
                    })
                    
                    self.presentAlertControllerWithTitle("Error loading note", message: theError.localizedDescription, preferredStyle: WKAlertControllerStyle.Alert, actions: [closeAction])
                    
                    return
                }
                
                if let theText = text {
                    self.noteContentLabel.setText(theText)
                }
            })
        }
        
    }
}

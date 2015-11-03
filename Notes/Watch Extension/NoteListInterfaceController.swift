//
//  InterfaceController.swift
//  Watch Extension
//
//  Created by Jon Manning on 3/11/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import WatchKit
import Foundation

class NoteRow : NSObject {
    
    @IBOutlet var nameLabel: WKInterfaceLabel!
    
    
}


class NoteListInterfaceController: WKInterfaceController {

    @IBOutlet var noteListTable: WKInterfaceTable!
    
    override func handleUserActivity(userInfo: [NSObject : AnyObject]?) {
        if userInfo?["editing"] as? Bool == true {
            createNote()
            invalidateUserActivity()            
        }
        
    }
    
    @IBAction func createNote() {
        self.presentTextInputControllerWithSuggestions(nil,
            allowedInputMode: WKTextInputMode.Plain) {
            (results) -> Void in
            
                if let text = results?.first as? String {
                    SessionManager.sharedSession.createNote(text, completionHandler: { notes, error in
                        self.updateListWithNotes(notes)
                    })
                }
                
                
        }
    }
    
    func updateListWithNotes(notes: [SessionManager.NoteInfo]) {
        self.noteListTable.setNumberOfRows(notes.count, withRowType: "NoteRow")
        
        for (i, note) in notes.enumerate() {
            if let row = self.noteListTable.rowControllerAtIndex(i) as? NoteRow {
                row.nameLabel.setText(note.name)
            }
        }
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        
        SessionManager.sharedSession.updateList { notes, error in
            self.updateListWithNotes(notes)
        }
    }
    
    override func contextForSegueWithIdentifier(segueIdentifier: String, inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
        
        if segueIdentifier == "ShowNote" {
            // Pass the URL for this note to the interface controller
            return SessionManager.sharedSession.notes[rowIndex].URL
        }
        
        return nil
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}

//
//  InterfaceController.swift
//  Watch Extension
//
//  Created by Jon Manning on 3/11/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import WatchKit
import Foundation

// BEGIN watch_noterow_controller
class NoteRow : NSObject {
    
    // BEGIN watch_noterow_controller_namelabel
    @IBOutlet var nameLabel: WKInterfaceLabel!
    // END watch_noterow_controller_namelabel
    
}
// END watch_noterow_controller


class NoteListInterfaceController: WKInterfaceController {

    @IBOutlet var noteListTable: WKInterfaceTable!
    
    // BEGIN watch_handle_user_activity
    override func handleUserActivity(userInfo: [NSObject : AnyObject]?) {
        if userInfo?["editing"] as? Bool == true {
            // Start creating a note
            createNote()
            
            // Clear the user activity
            invalidateUserActivity()            
        }
    }
    // END watch_handle_user_activity
    
    // BEGIN watch_create_note
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
    // END watch_create_note
    
    // BEGIN watch_update_list_with_notes
    func updateListWithNotes(notes: [SessionManager.NoteInfo]) {
        self.noteListTable.setNumberOfRows(notes.count, withRowType: "NoteRow")
        
        for (i, note) in notes.enumerate() {
            if let row = self.noteListTable.rowControllerAtIndex(i) as? NoteRow {
                row.nameLabel.setText(note.name)
            }
        }
    }
    // END watch_update_list_with_notes
    
    // BEGIN watch_list_awake
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        
        SessionManager.sharedSession.updateList() { notes, error in
            self.updateListWithNotes(notes)
        }
    }
    // END watch_list_awake
    
    // BEGIN watch_list_context_for_segue
    override func contextForSegueWithIdentifier(segueIdentifier: String,
        inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
        
        // Was this the ShowNote segue?
        if segueIdentifier == "ShowNote" {
            // Pass the URL for the selected note to the interface controller
            return SessionManager.sharedSession.notes[rowIndex].URL
        }
        
        return nil
    }
    // END watch_list_context_for_segue


}

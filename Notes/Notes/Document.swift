//
//  Document.swift
//  Notes
//
//  Created by Jonathon Manning on 24/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import Cocoa

let NotesErrorDomain = "NotesErrorDomain"

enum NotesErrorCode : Int {
    case CannotStoreRTF
    case CannotLoadRTF
}

class Document: NSDocument {
    
    // Main text content
    var text : NSAttributedString = NSAttributedString()

    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

    override var windowNibName: String? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return "Document"
    }

    override func dataOfType(typeName: String) throws -> NSData {
        
        // Attempt to convert the data into an NSData object that contains an RTFD representation of the document's text.
        if let RTFData = text.RTFDFromRange(NSRange(0..<text.length), documentAttributes: [:]) {
            return RTFData
        } else {
            // If that fails, throw an error.
            throw NSError(domain: NotesErrorDomain, code: NotesErrorCode.CannotStoreRTF.rawValue, userInfo: nil)
        }
        
    }

    override func readFromData(data: NSData, ofType typeName: String) throws {
        
        // Attempt to convert the provided data into an attributed string.
        if let attributedString = NSAttributedString(RTFD: data, documentAttributes: nil) {
            
            // If it worked, store it
            self.text = attributedString
        } else {
            
            // Otherwise, throw an error
            throw NSError(domain: NotesErrorDomain, code: NotesErrorCode.CannotLoadRTF.rawValue, userInfo: nil)
        }
        
        
    }


}


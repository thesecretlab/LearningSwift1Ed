//
//  DocumentCommon.swift
//  Notes
//
//  Created by Jonathon Manning on 26/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import Foundation

// BEGIN document_common
// We can be throwing a lot of errors in this class, and they'll all 
// be in the same error domain and using error codes from the same 
// enum, so here's a little convenience func to save typing and space

// BEGIN error_func
let ErrorDomain = "NotesErrorDomain"

func err(code: ErrorCode, _ userInfo:[NSObject:AnyObject]?=nil)  -> NSError {
    // Generate an NSError object, using ErrorDomain, and using whatever
    // value we were passed.
    return NSError(domain: ErrorDomain, code: code.rawValue, userInfo: userInfo)
}
// END error_func

// BEGIN document_file_names
// Names of files/directories in the package
enum NoteDocumentFileNames : String {
    /// The file that contains the text of the document, in
    /// Rich Text Format.
    case TextFile = "Text.rtf"
    
    /// The folder that all attachments will be kept in.
    case AttachmentsDirectory = "Attachments"
    
    /// The QuickLook folder.
    case QuickLookDirectory = "QuickLook"
    
    /// The QuickLook text file, which goes in the QuickLook directory.
    case QuickLookTextFile = "Preview.rtf"
}
// END document_file_names

/// Things that can go wrong.
// BEGIN error_codes
enum ErrorCode : Int {
    
    /// We couldn't find the document at all.
    case CannotAccessDocument
    
    /// We couldn't access any file wrappers inside this document.
    case CannotLoadFileWrappers
    
    /// We couldn't load the Text.rtf file.
    case CannotLoadText
    
    /// We couldn't access the Attachments folder.
    case CannotAccessAttachments
    
    /// We couldn't save the Text.rtf file.
    case CannotSaveText
    
    /// We couldn't save an attachment.
    case CannotSaveAttachment
}
// END error_codes
// END document_common

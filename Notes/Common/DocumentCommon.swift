//
//  DocumentCommon.swift
//  Notes
//
//  Created by Jonathon Manning on 26/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import Foundation

// We can be throwing a lot of errors in this class, and they'll all be in the same error domain and using error codes from the same enum, so here's a little convenience func to save typing and space
func err(code: ErrorCode, _ userInfo:[NSObject:AnyObject]?=nil)  -> NSError {
    return NSError(domain: ErrorDomain, code: code.rawValue, userInfo: userInfo)
}

let ErrorDomain = "NotesErrorDomain"

// Names of files/directories in the package
enum NoteDocumentFileNames : String {
    case DocumentFile = "Document.plist"
    case TextFile = "Text.rtf"
    case AttachmentsDirectory = "Attachments"
}

// Things that can go wrong.
enum ErrorCode : Int {
    case CannotAccessDocument
    case CannotLoadFileWrappers
    case CannotLoadText
    case CannotAccessAttachments
    case CannotSaveText
}

extension Document {
    
}
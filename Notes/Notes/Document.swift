//
//  Document.swift
//  Notes
//
//  Created by Jonathon Manning on 24/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import Cocoa

// We can be throwing a lot of errors in this class, and they'll all be in the same error domain and using error codes from the same enum, so here's a little convenience func to save typing and space
private func err(code: ErrorCode, _ userInfo:[NSObject:AnyObject]?=nil)  -> NSError {
    return NSError(domain: ErrorDomain, code: code.rawValue, userInfo: userInfo)
}

private let ErrorDomain = "NotesErrorDomain"

// Used for looking up data in Document.plist
private enum DocumentSummaryKeys : String {
    case Attachments = "attachments" // -> [String]
}

// Names of files/directories in the package
private enum FileNames : String {
    case DocumentFile = "Document.plist"
    case TextFile = "Text.rtf"
    case AttachmentsDirectory = "Attachments"
}

// Things that can go wrong.
private enum ErrorCode : Int {
    case CannotLoadFileWrappers
    case CannotLoadText
    case CannotAccessAttachments
    case CannotSaveText
}

class Document: NSDocument {
    
    // Main text content
    var text : NSAttributedString = NSAttributedString()
    
    // Attachments
    var attachedFiles : [String:NSFileWrapper]? {
        if let attachmentsDirectory = self.documentFileWrapper.fileWrappers?[FileNames.AttachmentsDirectory.rawValue], let attachmentsFileWrappers = attachmentsDirectory.fileWrappers {
            return attachmentsFileWrappers
        } else {
            return nil
        }
    }
    
    // Directory file wrapper
    var documentFileWrapper = NSFileWrapper(directoryWithFileWrappers: [:])

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
    
    override func readFromFileWrapper(fileWrapper: NSFileWrapper, ofType typeName: String) throws {
        
        
        
        // Ensure that we have additional file wrappers in this file wrapper
        guard let fileWrappers = fileWrapper.fileWrappers else {
            throw err(.CannotLoadFileWrappers)
        }
        
        // Ensure that we can access the document text
        guard let documentTextData = fileWrappers[FileNames.TextFile.rawValue]?.regularFileContents else {
            throw err(.CannotLoadText)
        }
        
        // Load the text data as RTF
        
        guard let documentText = NSAttributedString(RTF: documentTextData, documentAttributes: nil) else {
            throw err(.CannotLoadText)
        }
        
        // Keep the text in memory
        self.text = documentText
        
    }
    
    override func fileWrapperOfType(typeName: String) throws -> NSFileWrapper {
        
        let textRTFData = try self.text.dataFromRange(NSRange(0..<self.text.length), documentAttributes: [NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType])
        
        if let oldTextFileWrapper = self.documentFileWrapper.fileWrappers?[FileNames.TextFile.rawValue] {
            self.documentFileWrapper.removeFileWrapper(oldTextFileWrapper)
            
        }
        
        self.documentFileWrapper.addRegularFileWithContents(textRTFData, preferredFilename: FileNames.TextFile.rawValue)
        
        return self.documentFileWrapper
        
        
    }



}


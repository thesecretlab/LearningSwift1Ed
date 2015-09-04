//
//  Document.swift
//  Notes
//
//  Created by Jonathon Manning on 26/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import UIKit
import MobileCoreServices

// Type info and thumbnails
extension NSFileWrapper {
    func conformsToType(type: CFString) -> Bool {
        
        // Get the extension of this file
        guard let fileExtension = self.preferredFilename?.componentsSeparatedByString(".").last else {
            return false
        }
        
        // Get the file type of the attachment based on its extension
        guard let fileType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil)?.takeRetainedValue() else {
            return false
        }
        
        // Ask the system if this file type conforms to the provided type
        return UTTypeConformsTo(fileType, type)
    }
    
    func thumbnailImage() -> UIImage? {
        
        // Ensure that we can get the contents of the file
        guard let attachmentContent = self.regularFileContents else {
            return nil
        }
        
        if self.conformsToType(kUTTypeImage) {
            // If it's an image, return it as a UIImage
            return UIImage(data: attachmentContent)
        } else if self.conformsToType(kUTTypeJSON) {
            // JSON files used to store locations
            return UIImage(named: "Location")
        } else {
            // We don't know what type it is, so return a generic icon
            return UIImage(named: "File")
        }
    }

}

class Document: UIDocument {
    
    var text = NSAttributedString(string: "")
    
    var documentFileWrapper = NSFileWrapper(directoryWithFileWrappers: [:])
    
    // Attachments
    dynamic var attachedFiles : [NSFileWrapper]? {
        if let attachmentsDirectory = self.documentFileWrapper.fileWrappers?[NoteDocumentFileNames.AttachmentsDirectory.rawValue], let attachmentsFileWrappers = attachmentsDirectory.fileWrappers {
            let attachments = Array(attachmentsFileWrappers.values)
            
            return attachments
        } else {
            return nil
        }
    }
    
    private var attachmentsDirectoryWrapper : NSFileWrapper? {
        
        guard let fileWrappers = self.documentFileWrapper.fileWrappers else {
            NSLog("Attempting to access document's contents, but none found!")
            return nil
        }
        
        var attachmentsDirectoryWrapper = fileWrappers[NoteDocumentFileNames.AttachmentsDirectory.rawValue]
        
        if attachmentsDirectoryWrapper == nil {
            
            attachmentsDirectoryWrapper = NSFileWrapper(directoryWithFileWrappers: [:])
            
            attachmentsDirectoryWrapper?.preferredFilename = NoteDocumentFileNames.AttachmentsDirectory.rawValue
            
            self.documentFileWrapper.addFileWrapper(attachmentsDirectoryWrapper!)
        }
        
        return attachmentsDirectoryWrapper
    }
    
    override func contentsForType(typeName: String) throws -> AnyObject {
        
        let textRTFData = try self.text.dataFromRange(NSRange(0..<self.text.length), documentAttributes: [NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType])
        
        if let oldTextFileWrapper = self.documentFileWrapper.fileWrappers?[NoteDocumentFileNames.TextFile.rawValue] {
            self.documentFileWrapper.removeFileWrapper(oldTextFileWrapper)
            
        }
        
        self.documentFileWrapper.addRegularFileWithContents(textRTFData, preferredFilename: NoteDocumentFileNames.TextFile.rawValue)
        
        return self.documentFileWrapper
    }

    override func loadFromContents(contents: AnyObject, ofType typeName: String?) throws {
        
        // Ensure that we've been given a file wrapper
        guard let fileWrapper = contents as? NSFileWrapper else {
            throw err(.CannotLoadFileWrappers)
        }
        
        // Ensure that this file wrapper contains the text file,
        // and that we can read it
        guard let textFileWrapper = fileWrapper.fileWrappers?[NoteDocumentFileNames.TextFile.rawValue], let textFileData = textFileWrapper.regularFileContents else {
            throw err(.CannotLoadText)
        }
        
        // Read in the RTF
        self.text = try NSAttributedString(data: textFileData, options: [NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType], documentAttributes: nil)
        
        // Keep a reference to the file wrapper
        self.documentFileWrapper = fileWrapper
        
    }
    
    // Given an attachment, eventually returns its URL, if possible.
    // It might be nil if 1. this isn't one of our attachments or
    // 2. we failed to save, in which case the attachment may not exist
    // on disk
    func URLForAttachment(attachment: NSFileWrapper, completion: NSURL? -> Void) {
        
        // Ensure that this is an attachment we have
        guard let attachments = self.attachedFiles where attachments.contains(attachment) else {
            completion(nil)
            return
        }
        
        // Ensure that this attachment has a filename
        guard let fileName = attachment.preferredFilename else {
            completion(nil)
            return
        }
        
        self.autosaveWithCompletionHandler { (success) -> Void in
            if success {
                
                // We're now certain that attachments actually
                // exit on disk, so we can get their URL
                let attachmentURL = self.fileURL.URLByAppendingPathComponent(NoteDocumentFileNames.AttachmentsDirectory.rawValue, isDirectory: true).URLByAppendingPathComponent(fileName)
                
                completion(attachmentURL)
                
            } else {
                NSLog("Failed to autosave!")
                completion(nil)
            }
        }
        
    }
    
    func addAttachmentAtURL(url:NSURL) throws {
        
        guard attachmentsDirectoryWrapper != nil else {
            throw err(.CannotAccessAttachments)
        }
        
        self.willChangeValueForKey("attachedFiles")
        
        let newAttachment = try NSFileWrapper(URL: url, options: NSFileWrapperReadingOptions.Immediate)
        
        attachmentsDirectoryWrapper?.addFileWrapper(newAttachment)
        
        self.updateChangeCount(.Done)
        self.didChangeValueForKey("attachedFiles")
    }
    
    
    
    func addAttachmentWithData(data: NSData, name: String) throws {
        
        guard attachmentsDirectoryWrapper != nil else {
            throw err(.CannotAccessAttachments)
        }
        
        let newAttachment = NSFileWrapper(regularFileWithContents: data)
        
        newAttachment.preferredFilename = name
        
        attachmentsDirectoryWrapper?.addFileWrapper(newAttachment)
        
        self.updateChangeCount(.Done)
        
    }
    
    func deleteAttachment(attachment:NSFileWrapper) throws {
        
        guard attachmentsDirectoryWrapper != nil else {
            throw err(.CannotAccessAttachments)
        }
        
        
        attachmentsDirectoryWrapper?.removeFileWrapper(attachment)
        
        self.updateChangeCount(.Done)
        
    }
    
    
}

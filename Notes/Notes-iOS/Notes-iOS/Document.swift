//
//  Document.swift
//  Notes
//
//  Created by Jonathon Manning on 26/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import UIKit

// BEGIN import_mobilecoreservices
import MobileCoreServices
// END import_mobilecoreservices

// Type info and thumbnails

// BEGIN filewrapper_extension
extension NSFileWrapper {
    
    // BEGIN conforms_to_type
    func conformsToType(type: CFString) -> Bool {
        
        // Get the extension of this file
        guard let fileExtension = self.preferredFilename?.componentsSeparatedByString(".").last else {
            // If we can't get a file extension, assume that it doesn't conform
            return false
        }
        
        // Get the file type of the attachment based on its extension
        guard let fileType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil)?.takeRetainedValue() else {
            // If we can't figure out the file type from the extension, it also doesn't conform
            return false
        }
        
        // Ask the system if this file type conforms to the provided type
        return UTTypeConformsTo(fileType, type)
    }
    // END conforms_to_type
    
    // BEGIN thumbnail_image
    func thumbnailImage() -> UIImage? {
        
        if self.conformsToType(kUTTypeImage) {
            // If it's an image, return it as a UIImage
            
            // Ensure that we can get the contents of the file
            guard let attachmentContent = self.regularFileContents else {
                return nil
            }
            
            // Attempt to
            return UIImage(data: attachmentContent)
        }
        
        if self.conformsToType(kUTTypeJSON) {
            // JSON files used to store locations
            return UIImage(named: "Location")
        }
        
        // We don't know what type it is, so return a generic icon
        return UIImage(named: "File")
    }
    // END thumbnail_image

}
// END filewrapper_extension

class Document: UIDocument {
    
    // BEGIN document_base
    var text = NSAttributedString(string: "")
    
    var documentFileWrapper = NSFileWrapper(directoryWithFileWrappers: [:])
    
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
    // END document_base
    
    // BEGIN document_attachment_dir
    private var attachmentsDirectoryWrapper : NSFileWrapper? {
        
        // Ensure that we can actually work with this document
        guard let fileWrappers = self.documentFileWrapper.fileWrappers else {
            NSLog("Attempting to access document's contents, but none found!")
            return nil
        }
        
        // Try to get the attachments directory
        var attachmentsDirectoryWrapper = fileWrappers[NoteDocumentFileNames.AttachmentsDirectory.rawValue]
        
        // If it doesn't exist..
        if attachmentsDirectoryWrapper == nil {
            
            // Create it
            attachmentsDirectoryWrapper = NSFileWrapper(directoryWithFileWrappers: [:])
            attachmentsDirectoryWrapper?.preferredFilename = NoteDocumentFileNames.AttachmentsDirectory.rawValue
            
            // And then add it
            self.documentFileWrapper.addFileWrapper(attachmentsDirectoryWrapper!)
            
            // We made a change to the file, so record that
            self.updateChangeCount(UIDocumentChangeKind.Done)
        }
        
        // Either way, return it
        return attachmentsDirectoryWrapper
    }
    // END document_attachment_dir
    
    // Attachments
    // BEGIN document_attachments
    dynamic var attachedFiles : [NSFileWrapper]? {
        
        // Get the contents of the attachments directory directory
        guard let attachmentsFileWrappers = attachmentsDirectoryWrapper?.fileWrappers else {
            NSLog("Can't access the attachments directory!")
            return nil
        }
        
        // attachmentsFileWrappers is a dictionary mapping filenames
        // to NSFileWrapper objects; we only care about the NSFileWrappers,
        // so return that as an array
        return Array(attachmentsFileWrappers.values)
            
    }
    // END document_attachments

    // BEGIN document_add_attachments
    func addAttachmentAtURL(url:NSURL) throws {
        
        // Ensure that we have a place to put attachments
        guard attachmentsDirectoryWrapper != nil else {
            throw err(.CannotAccessAttachments)
        }
        
        // Create the new attachment with this file, or throw an error
        let newAttachment = try NSFileWrapper(URL: url,
            options: NSFileWrapperReadingOptions.Immediate)
        
        // Add it to the attachments directory
        attachmentsDirectoryWrapper?.addFileWrapper(newAttachment)
        
        // Mark ourselves as needing to save
        self.updateChangeCount(UIDocumentChangeKind.Done)
    }
    // END document_add_attachments
    
    
    
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

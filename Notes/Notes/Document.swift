//
//  Document.swift
//  Notes
//
//  Created by Jonathon Manning on 24/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import Cocoa


// BEGIN filewrapper_icon
extension NSFileWrapper {
    dynamic var thumbnailImage : NSImage {
        
        if let fileExtension = self.preferredFilename?.componentsSeparatedByString(".").last {
            return NSWorkspace.sharedWorkspace().iconForFileType(fileExtension)
        } else {
            return NSWorkspace.sharedWorkspace().iconForFileType("")
        }
    }
}
// END filewrapper_icon

class Document: NSDocument, AttachmentViewDelegate {
    
    // BEGIN text_property
    // Main text content
    var text : NSAttributedString = NSAttributedString()
    // END text_property
    
    // BEGIN document_file_wrapper
    // Directory file wrapper
    var documentFileWrapper = NSFileWrapper(directoryWithFileWrappers: [:])
    // END document_file_wrapper
    
    // Attachments
    // BEGIN attached_files_property
    dynamic var attachedFiles : [NSFileWrapper]? {
        if let attachmentsDirectory = self.documentFileWrapper
            .fileWrappers?[NoteDocumentFileNames.AttachmentsDirectory.rawValue],
            let attachmentsFileWrappers = attachmentsDirectory.fileWrappers {
                
            let attachments = Array(attachmentsFileWrappers.values)
            
            return attachments
                
        } else {
            return nil
        }
    }
    // END attached_files_property
    
    // BEGIN attachments_directory
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
    // END attachments_directory

    override class func autosavesInPlace() -> Bool {
        return true
    }

    override var windowNibName: String? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return "Document"
    }
    
    // BEGIN read_from_file_wrapper
    override func readFromFileWrapper(fileWrapper: NSFileWrapper,
        ofType typeName: String) throws {
        
        // Ensure that we have additional file wrappers in this file wrapper
        guard let fileWrappers = fileWrapper.fileWrappers else {
            throw err(.CannotLoadFileWrappers)
        }
        
        // Ensure that we can access the document text
        guard let documentTextData =
            fileWrappers[NoteDocumentFileNames.TextFile.rawValue]?
                .regularFileContents else {
            throw err(.CannotLoadText)
        }
        
        // Load the text data as RTF
        guard let documentText = NSAttributedString(RTF: documentTextData,
            documentAttributes: nil) else {
            throw err(.CannotLoadText)
        }
        
        // Keep the text in memory
        self.documentFileWrapper = fileWrapper
        
        self.text = documentText
        
    }
    // END read_from_file_wrapper
    
    // BEGIN file_wrapper_of_type
    override func fileWrapperOfType(typeName: String) throws -> NSFileWrapper {
        
        let textRTFData = try self.text.dataFromRange(NSRange(0..<self.text.length), documentAttributes: [NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType])
        
        // If the current document file wrapper already contains a
        // text file, remove it - we'll replace it with a new one
        if let oldTextFileWrapper = self.documentFileWrapper.fileWrappers?[NoteDocumentFileNames.TextFile.rawValue] {
            self.documentFileWrapper.removeFileWrapper(oldTextFileWrapper)
        }
        
        // Save the text data into the file
        self.documentFileWrapper.addRegularFileWithContents(textRTFData, preferredFilename: NoteDocumentFileNames.TextFile.rawValue)
        
        // Return the main document's file wrapper - this is what will
        // be saved on disk
        return self.documentFileWrapper
    }
    // END file_wrapper_of_type

    // BEGIN popover
    var popover : NSPopover?
    // END popover


    // BEGIN add_attachment_method
    @IBAction func addAttachment(sender: NSButton) {
        
        if let viewController = AddAttachmentViewController(nibName:"AddAttachmentViewController", bundle:NSBundle.mainBundle()) {
            
            // BEGIN add_attachment_method
            viewController.delegate = self
            // END add_attachment_method
            
            self.popover = NSPopover()
            
            self.popover?.behavior = .Transient
            
            self.popover?.contentViewController = viewController
            
            self.popover?.showRelativeToRect(sender.bounds, ofView: sender, preferredEdge: NSRectEdge.MaxY)
        }
        
    }
    // END add_attachment_method
    
    
    
    // BEGIN add_attachment_at_url
    func addAttachmentAtURL(url:NSURL) throws {
        
        guard attachmentsDirectoryWrapper != nil else {
            throw err(.CannotAccessAttachments)
        }
        
        self.willChangeValueForKey("attachedFiles")
        
        let newAttachment = try NSFileWrapper(URL: url, options: NSFileWrapperReadingOptions.Immediate)
        
        attachmentsDirectoryWrapper?.addFileWrapper(newAttachment)
        
        self.updateChangeCount(.ChangeDone)
        self.didChangeValueForKey("attachedFiles")
    }
    // END add_attachment_at_url
    
    @IBOutlet weak var attachmentsArrayController : NSArrayController?
    

    
    func openSelectedAttachment() {
        if let selection = (self.attachmentsArrayController?.selection as? NSObjectController)?.content as? NSFileWrapper {
            
            // Ensure that the document is saved
            self.autosaveWithImplicitCancellability(false, completionHandler: { (error) -> Void in
                
                var url = self.fileURL
                url = url?.URLByAppendingPathComponent(NoteDocumentFileNames.AttachmentsDirectory.rawValue, isDirectory: true)
                url = url?.URLByAppendingPathComponent(selection.preferredFilename!)
                
                
                NSWorkspace.sharedWorkspace().openURL(url!)
                
            })
            
        }
    }

}

// BEGIN document_addattachmentdelegate_extension
extension Document : AddAttachmentDelegate {
    
    // BEGIN document_addattachmentdelegate_extension_impl
    // BEGIN add_file
    func addFile() {
        
        let panel = NSOpenPanel()
        
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        
        panel.beginWithCompletionHandler { (result) -> Void in
            if result == NSModalResponseOK {
                
                if let resultURL = panel.URLs.first {
                    do {
                        // We were given a URL - copy it in!
                        try self.addAttachmentAtURL(resultURL)
                    } catch let error as NSError {
                        
                        // There was an error - show the user
                        NSApp.presentError(error,
                            modalForWindow: self.windowForSheet!,
                            delegate: nil,
                            didPresentSelector: nil,
                            contextInfo: nil)
                        
                    } catch {
                        
                    }
                }
                
            }
        }
        
        
    }
    // END add_file
    // END document_addattachmentdelegate_extension_impl
}
// END document_addattachmentdelegate_extension



@objc
protocol AttachmentViewDelegate : NSObjectProtocol {
    func openSelectedAttachment()
}

@objc
class AttachmentView : NSView {
    
    @IBOutlet weak var delegate : AnyObject!
    
    override func mouseDown(theEvent: NSEvent) {
        if theEvent.clickCount == 2 {
            (self.delegate as? AttachmentViewDelegate)?.openSelectedAttachment()
        }
        super.mouseDown(theEvent)
    }
}

/*
// Not included in the class because we're actually using readFromFileWrapper 
// and fileWrapperOfType, and having implementations of readFromData and 
// dataOfType in the class changes the behaviour of the NSDocument system

// BEGIN read_from_data
override func readFromData(data: NSData, ofType typeName: String) throws {
    // Load data from "data".
}
// END read_from_data

// BEGIN data_of_type
override func dataOfType(typeName: String) throws -> NSData {
    // Return an NSData object.
    return "Hello".dataUsingEncoding(NSUTF8StringEncoding)!
}
// END data_of_type
*/



//
//  Document.swift
//  Notes
//
//  Created by Jonathon Manning on 24/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import Cocoa


extension NSFileWrapper {
    dynamic var thumbnailImage : NSImage {
        
        if let fileExtension = self.preferredFilename?.componentsSeparatedByString(".").last {
            return NSWorkspace.sharedWorkspace().iconForFileType(fileExtension)
        } else {
            return NSWorkspace.sharedWorkspace().iconForFileType("")
        }
    }
}

class Document: NSDocument, AddAttachmentDelegate, AttachmentViewDelegate {
    
    // Main text content
    var text : NSAttributedString = NSAttributedString()
    
    // Directory file wrapper
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
        guard let documentTextData = fileWrappers[NoteDocumentFileNames.TextFile.rawValue]?.regularFileContents else {
            throw err(.CannotLoadText)
        }
        
        // Load the text data as RTF
        
        guard let documentText = NSAttributedString(RTF: documentTextData, documentAttributes: nil) else {
            throw err(.CannotLoadText)
        }
        
        // Keep the text in memory
        self.documentFileWrapper = fileWrapper
        
        self.text = documentText
        
    }
    
    override func fileWrapperOfType(typeName: String) throws -> NSFileWrapper {
        
        let textRTFData = try self.text.dataFromRange(NSRange(0..<self.text.length), documentAttributes: [NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType])
        
        if let oldTextFileWrapper = self.documentFileWrapper.fileWrappers?[NoteDocumentFileNames.TextFile.rawValue] {
            self.documentFileWrapper.removeFileWrapper(oldTextFileWrapper)
            
        }
        
        self.documentFileWrapper.addRegularFileWithContents(textRTFData, preferredFilename: NoteDocumentFileNames.TextFile.rawValue)
        
        return self.documentFileWrapper
        
        
    }

    var popover : NSPopover?

    @IBAction func addAttachment(sender: NSButton) {
        
        if let viewController = AddAttachmentViewController(nibName:"AddAttachmentViewController", bundle:NSBundle.mainBundle()) {
            
            viewController.delegate = self
            
            self.popover = NSPopover()
            
            self.popover?.behavior = .Transient
            
            self.popover?.contentViewController = viewController
            
            self.popover?.showRelativeToRect(sender.bounds, ofView: sender, preferredEdge: NSRectEdge.MaxY)
        }
        
    }
    
    
    
    func addFile() {
        
        let panel = NSOpenPanel()
        
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        
        panel.beginWithCompletionHandler { (result) -> Void in
            if result == NSModalResponseOK {
                
                if let resultURL = panel.URLs.first {
                    do {
                        try self.addAttachmentAtURL(resultURL)
                    } catch let error as NSError {
                        NSApp.presentError(error, modalForWindow: self.windowForSheet!, delegate: nil, didPresentSelector: nil, contextInfo: nil)
                    } catch {
                        
                    }
                }
                
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
        
        self.updateChangeCount(.ChangeDone)
        self.didChangeValueForKey("attachedFiles")
    }
    
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



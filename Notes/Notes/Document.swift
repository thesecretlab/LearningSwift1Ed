//
//  Document.swift
//  Notes
//
//  Created by Jonathon Manning on 24/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import Cocoa

class Document: NSDocument, AddAttachmentDelegate {
    
    // Main text content
    var text : NSAttributedString = NSAttributedString()
    
    // Attachments
    dynamic var attachedFiles : [NSFileWrapper]? {
        if let attachmentsDirectory = self.documentFileWrapper.fileWrappers?[NoteDocumentFileNames.AttachmentsDirectory.rawValue], let attachmentsFileWrappers = attachmentsDirectory.fileWrappers {
            return Array(attachmentsFileWrappers.values)
        } else {
            return nil
        }
    }
    
    func addAttachmentAtURL(url:NSURL) throws {
        // Ensure that we have an Attachments folder to store stuff in
        
        guard let fileWrappers = self.documentFileWrapper.fileWrappers else {
            throw err(.CannotAccessAttachments)
        }
        
        self.willChangeValueForKey("attachedFiles")
        
        var attachmentsDirectoryWrapper = fileWrappers[NoteDocumentFileNames.AttachmentsDirectory.rawValue]
        
        if attachmentsDirectoryWrapper == nil {
            
            attachmentsDirectoryWrapper = NSFileWrapper(directoryWithFileWrappers: [:])
            
            attachmentsDirectoryWrapper?.preferredFilename = NoteDocumentFileNames.AttachmentsDirectory.rawValue
            
            self.documentFileWrapper.addFileWrapper(attachmentsDirectoryWrapper!)
        }
        
        let newAttachment = try NSFileWrapper(URL: url, options: NSFileWrapperReadingOptions.Immediate)
        
        attachmentsDirectoryWrapper?.addFileWrapper(newAttachment)
        
        self.updateChangeCount(NSDocumentChangeType.ChangeDone)
        self.didChangeValueForKey("attachedFiles")
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
    
//    func collectionView(collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
//        return self.attachedFiles?.count ?? 0
//    }
//    
//    func collectionView(collectionView: NSCollectionView, itemForRepresentedObjectAtIndexPath indexPath: NSIndexPath) -> NSCollectionViewItem {
//        
//        let collectionItem = NSCollectionViewItem()
//        collectionItem.textField?.stringValue = "Hi"
//        
//        return collectionItem
//        
//    }

}


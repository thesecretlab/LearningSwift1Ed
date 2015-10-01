//
//  Document.swift
//  Notes
//
//  Created by Jonathon Manning on 24/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import Cocoa
import MapKit
import AddressBook
import CoreLocation
import QuickLook

// BEGIN filewrapper_icon
extension NSFileWrapper {
    
    dynamic var fileExtension : String? {
        return self.preferredFilename?.componentsSeparatedByString(".").last
    }
    
    dynamic var thumbnailImage : NSImage {
        
        if let fileExtension = self.fileExtension {
            return NSWorkspace.sharedWorkspace().iconForFileType(fileExtension)
        } else {
            return NSWorkspace.sharedWorkspace().iconForFileType("")
        }
    }
    
    func conformsToType(type: CFString) -> Bool {
        
        // Get the extension of this file
        guard let fileExtension = self.preferredFilename?
            .componentsSeparatedByString(".").last else {
                // If we can't get a file extension, assume that it doesn't conform
                return false
        }
        
        // Get the file type of the attachment based on its extension
        guard let fileType = UTTypeCreatePreferredIdentifierForTag(
            kUTTagClassFilenameExtension, fileExtension, nil)?
            .takeRetainedValue() else {
                // If we can't figure out the file type from the extension,
                // it also doesn't conform
                return false
        }
        
        // Ask the system if this file type conforms to the provided type
        return UTTypeConformsTo(fileType, type)
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
    
    @IBOutlet var attachmentsList : NSCollectionView!
    
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
    
    override func windowControllerDidLoadNib(windowController: NSWindowController) {
        self.attachmentsList.registerForDraggedTypes([NSURLPboardType])
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
        
        // Create the QuickLook folder
        let quicklookPreview = NSFileWrapper(regularFileWithContents: textRTFData)
        let quickLookFolderFileWrapper = NSFileWrapper(directoryWithFileWrappers: [NoteDocumentFileNames.QuickLookTextFile.rawValue:quicklookPreview])
        quickLookFolderFileWrapper.preferredFilename = NoteDocumentFileNames.QuickLookDirectory.rawValue
        
        // Remove the old QuickLook folder if it existed
        if let oldQuickLookFolder = self.documentFileWrapper
            .fileWrappers?[NoteDocumentFileNames.QuickLookDirectory.rawValue] {
            self.documentFileWrapper.removeFileWrapper(oldQuickLookFolder)
        }
        
        // Add the new QuickLook folder
        self.documentFileWrapper.addFileWrapper(quickLookFolderFileWrapper)
        
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
            
            // BEGIN add_attachment_method_delegate
            viewController.delegate = self
            // END add_attachment_method_delegate
            
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
        if let selection = self.attachedFiles?[self.attachmentsArrayController?.selectionIndex ?? 0] {
            
            // Ensure that the document is saved
            self.autosaveWithImplicitCancellability(false, completionHandler: { (error) -> Void in
                
                if selection.conformsToType(kUTTypeJSON),
                    let data = selection.regularFileContents,
                    let json = try? NSJSONSerialization
                        .JSONObjectWithData(data, options: NSJSONReadingOptions())
                        as? NSDictionary  {
                    
                    if let lat = json?["lat"] as? CLLocationDegrees,
                        let lon = json?["long"] as? CLLocationDegrees {
                            
                            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                            
                            let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
                            
                            let mapItem = MKMapItem(placemark: placemark)
                            
                            mapItem.openInMapsWithLaunchOptions(nil);
                    
                    }
                            
                    
                } else {
                    
                    var url = self.fileURL
                    url = url?.URLByAppendingPathComponent(NoteDocumentFileNames.AttachmentsDirectory.rawValue, isDirectory: true)
                    url = url?.URLByAppendingPathComponent(selection.preferredFilename!)
                    
                    NSWorkspace.sharedWorkspace().openURL(url!)
                }
                
                
                
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

// BEGIN collectionview_dragndrop
extension Document : NSCollectionViewDelegate {
    func collectionView(collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndex proposedDropIndex: UnsafeMutablePointer<Int>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionViewDropOperation>) -> NSDragOperation {
        
        return NSDragOperation.Copy
    }
    
    func collectionView(collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, index: Int, dropOperation: NSCollectionViewDropOperation) -> Bool {

        let pasteboard = draggingInfo.draggingPasteboard()
        
        if pasteboard.types?.contains(NSURLPboardType) == true,
            let url = NSURL(fromPasteboard: pasteboard)
        {
            NSLog("Dropped \(url.path)")
            do {
                try self.addAttachmentAtURL(url)
            } catch let error as NSError {
                self.presentError(error)
                return false
            }
            return true
        }
        
        return false
    }
}
// END collectionview_dragndrop

@objc
protocol AttachmentViewDelegate : NSObjectProtocol {
    func openSelectedAttachment()
}

@objc
class AttachmentView : NSView {
    
    
    
    @IBOutlet weak var delegate : AnyObject!
    
    override func mouseDown(theEvent: NSEvent) {
        if theEvent.clickCount > 1 {
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




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

class Document: NSDocument {
    
    // BEGIN text_property
    // Main text content
    var text : NSAttributedString = NSAttributedString()
    // END text_property
    
    // Directory file wrapper
    // BEGIN document_file_wrapper
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

    // BEGIN osx_window_nib_name
    override var windowNibName: String? {
        //- Returns the nib file name of the document
        //- If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return "Document"
    }
    // END osx_window_nib_name
    
    // BEGIN did_load_nib
    override func windowControllerDidLoadNib(windowController: NSWindowController) {
        self.attachmentsList.registerForDraggedTypes([NSURLPboardType])
    }
    // END did_load_nib
    
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
        
        // BEGIN error_example
        // Load the text data as RTF
        guard let documentText = NSAttributedString(RTF: documentTextData,
            documentAttributes: nil) else {
            throw err(.CannotLoadText)
        }
        // END error_example
        
        // Keep the text in memory
        self.documentFileWrapper = fileWrapper
        
        self.text = documentText
        
    }
    // END read_from_file_wrapper
    
    // BEGIN file_wrapper_of_type
    override func fileWrapperOfType(typeName: String) throws -> NSFileWrapper {
        
        // BEGIN file_wrapper_of_type_rtf_load
        let textRTFData = try self.text.dataFromRange(
            NSRange(0..<self.text.length),
            documentAttributes: [
                NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType
            ]
        )
        // END file_wrapper_of_type_rtf_load
        
        // If the current document file wrapper already contains a
        // text file, remove it - we'll replace it with a new one
        if let oldTextFileWrapper = self.documentFileWrapper
            .fileWrappers?[NoteDocumentFileNames.TextFile.rawValue] {
            self.documentFileWrapper.removeFileWrapper(oldTextFileWrapper)
        }
        
        // BEGIN file_wrapper_of_type_quicklook
        // Create the QuickLook folder
        
        let thumbnailImageData = self.iconImageDataWithSize(CGSize(width: 512, height: 512))!
        let thumbnailWrapper = NSFileWrapper(regularFileWithContents: thumbnailImageData)
        
        let quicklookPreview = NSFileWrapper(regularFileWithContents: textRTFData)
        let quickLookFolderFileWrapper = NSFileWrapper(directoryWithFileWrappers: [
            NoteDocumentFileNames.QuickLookTextFile.rawValue: quicklookPreview,
            NoteDocumentFileNames.QuickLookThumbnail.rawValue: thumbnailWrapper
            ])
        
        quickLookFolderFileWrapper.preferredFilename
            = NoteDocumentFileNames.QuickLookDirectory.rawValue
        
        // Remove the old QuickLook folder if it existed
        if let oldQuickLookFolder = self.documentFileWrapper
            .fileWrappers?[NoteDocumentFileNames.QuickLookDirectory.rawValue] {
            self.documentFileWrapper.removeFileWrapper(oldQuickLookFolder)
        }
        
        // Add the new QuickLook folder
        self.documentFileWrapper.addFileWrapper(quickLookFolderFileWrapper)
        // END file_wrapper_of_type_quicklook
        
        // Save the text data into the file
        self.documentFileWrapper.addRegularFileWithContents(
            textRTFData,
            preferredFilename: NoteDocumentFileNames.TextFile.rawValue
        )
        
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
        
        if let viewController = AddAttachmentViewController(
            nibName:"AddAttachmentViewController", bundle:NSBundle.mainBundle()
            ) {
            
            // BEGIN add_attachment_method_delegate
            viewController.delegate = self
            // END add_attachment_method_delegate
            
            self.popover = NSPopover()
            
            self.popover?.behavior = .Transient
            
            self.popover?.contentViewController = viewController
            
            self.popover?.showRelativeToRect(sender.bounds,
                ofView: sender, preferredEdge: NSRectEdge.MaxY)
        }
        
    }
    // END add_attachment_method
    
    
    
    // BEGIN add_attachment_at_url
    func addAttachmentAtURL(url:NSURL) throws {
        
        guard attachmentsDirectoryWrapper != nil else {
            throw err(.CannotAccessAttachments)
        }
        
        self.willChangeValueForKey("attachedFiles")
        
        let newAttachment = try NSFileWrapper(URL: url,
            options: NSFileWrapperReadingOptions.Immediate)
        
        attachmentsDirectoryWrapper?.addFileWrapper(newAttachment)
        
        self.updateChangeCount(.ChangeDone)
        self.didChangeValueForKey("attachedFiles")
    }
    // END add_attachment_at_url
    
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
            if result == NSModalResponseOK,
                let resultURL = panel.URLs.first {
            
                do {
                    // We were given a URL - copy it in!
                    try self.addAttachmentAtURL(resultURL)
                    
                    // Refresh the attachments list
                    self.attachmentsList?.reloadData()
                    
                } catch let error as NSError {
                    
                    // There was an error adding the attachment.
                    // Show the user!
                    
                    // Try to get a window to present a sheet in
                    if let window = self.windowForSheet {
                        
                        // Present the error in a sheet
                        NSApp.presentError(error,
                            modalForWindow: window,
                            delegate: nil,
                            didPresentSelector: nil,
                            contextInfo: nil)
                        
                        
                    } else {
                        // No window, so present it in a dialog box
                        NSApp.presentError(error)
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
    
    func collectionView(collectionView: NSCollectionView,
        validateDrop draggingInfo: NSDraggingInfo,
        proposedIndexPath proposedDropIndexPath:
            AutoreleasingUnsafeMutablePointer<NSIndexPath?>,
        dropOperation proposedDropOperation:
            UnsafeMutablePointer<NSCollectionViewDropOperation>)
        -> NSDragOperation {
            
        // Indicate to the user that if they release the mouse button,
        // it will "copy" whatever they're dragging.
        return NSDragOperation.Copy
    }
    
    
    func collectionView(collectionView: NSCollectionView,
        acceptDrop draggingInfo: NSDraggingInfo,
        indexPath: NSIndexPath,
        dropOperation: NSCollectionViewDropOperation) -> Bool {
            
        // Get the pasteboard that contains the info the user dropped
        let pasteboard = draggingInfo.draggingPasteboard()
        
        // If the pasteboard contains a URL, and we can get that URL...
        if pasteboard.types?.contains(NSURLPboardType) == true,
            let url = NSURL(fromPasteboard: pasteboard)
        {
            // Then attempt to add that as an attachment!
            NSLog("Dropped \(url.path)")
            do {
                // Add it to the document
                try self.addAttachmentAtURL(url)
                
                // Reload the attachments list to display it
                attachmentsList.reloadData()
                
                // It succeeded!
                return true
            } catch let error as NSError {
                
                // Uhoh. Present the error in a dialog box.
                self.presentError(error)
                
                // It failed, so tell the system to animate the
                // dropped item back to where it came from
                return false
            }
            
        }
        
        return false
    }
    
}
// END collectionview_dragndrop

// BEGIN collectionview_datasource
extension Document : NSCollectionViewDataSource {
    
    // BEGIN collectionview_datasource_numberofitems
    func collectionView(collectionView: NSCollectionView,
        numberOfItemsInSection section: Int) -> Int {
            
        // The number of items is equal to the number of
        // attachments we have. If for some reason we can't
        // access attachedFiles, we have zero items.
        return self.attachedFiles?.count ?? 0
    }
    // END collectionview_datasource_numberofitems
    
    // BEGIN collectionview_datasource_item
    func collectionView(collectionView: NSCollectionView,
        itemForRepresentedObjectAtIndexPath indexPath: NSIndexPath)
        -> NSCollectionViewItem {
            
        // Get the attachment that this cell should represent
        let attachment = self.attachedFiles![indexPath.item]
        
        // Get the cell itself
        let item = collectionView
            .makeItemWithIdentifier("AttachmentCell", forIndexPath: indexPath)
            as! AttachmentCell
        
        // Display the image and file extension in the ecell
        item.imageView?.image = attachment.thumbnailImage
        item.textField?.stringValue = attachment.fileExtension ?? ""
        
        // BEGIN collectionview_datasource_item_delegate
        // Make this cell use us as its delegate
        item.delegate = self
        // END collectionview_datasource_item_delegate
        
        return item
    }
    // END collectionview_datasource_item
    
}
// END collectionview_datasource

// BEGIN document_open_selected_attachment
extension Document : AttachmentCellDelegate {
    func openSelectedAttachment(collectionItem: NSCollectionViewItem) {
        
        // Get the index of this item, or bail out
        guard let selectedIndex = self.attachmentsList
            .indexPathForItem(collectionItem)?.item else {
            return
        }
        
        // Get the attachment in question, or bail out
        guard let attachment = self.attachedFiles?[selectedIndex] else {
            return
        }
    
        // First, ensure that the document is saved
        self.autosaveWithImplicitCancellability(false, completionHandler: { (error) -> Void in
            
            // BEGIN document_open_selected_attachment_location
            if attachment.conformsToType(kUTTypeJSON),
                let data = attachment.regularFileContents,
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
                // END document_open_selected_attachment_location
                
                var url = self.fileURL
                url = url?.URLByAppendingPathComponent(
                    NoteDocumentFileNames.AttachmentsDirectory.rawValue, isDirectory: true)
                url = url?.URLByAppendingPathComponent(attachment.preferredFilename!)
                
                if let path = url?.path {
                    NSWorkspace.sharedWorkspace().openFile(
                        path, withApplication: nil, andDeactivate: true)
                }
                
                
                // BEGIN document_open_selected_attachment_location
            }
            // END document_open_selected_attachment_location
        })
        
    }

}
// END document_open_selected_attachment


// BEGIN attachment_view_delegate_protocol
@objc protocol AttachmentCellDelegate : NSObjectProtocol {
    func openSelectedAttachment(collectionViewItem : NSCollectionViewItem)
}
// END attachment_view_delegate_protocol

// Note: Not actually used in the app, but included to give
// an example of how you'd implement a flat-file document.

// These methods are not included in the main Document class
// because we're actually using readFromFileWrapper and
// fileWrapperOfType, and having implementations of readFromData and
// dataOfType in the class changes the behaviour of the NSDocument system.

// PS: These comments aren't in the book, which means that if you're
// in here and reading this, you're pretty dedicated. Hi there! Hope 
// you're doing well today! Ping us on Twitter at @thesecretlab if you liked
// the book! :)

class FlatFileDocumentExample : NSDocument {

    // BEGIN read_from_data
    override func readFromData(data: NSData, ofType typeName: String) throws {
        // Load data from "data".
    }
    // END read_from_data

    // BEGIN data_of_type
    override func dataOfType(typeName: String) throws -> NSData {
        // Return an NSData object. Here's an example:
        return "Hello".dataUsingEncoding(NSUTF8StringEncoding)!
    }
    // END data_of_type
}

// Icons

extension Document {
    
    // BEGIN document_icon_data
    func iconImageDataWithSize(size: CGSize) -> NSData? {
        
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        let entireImageRect = CGRect(origin: CGPoint.zero, size: size)
        
        // Fill the background with white
        let backgroundRect = NSBezierPath(rect: entireImageRect)
        NSColor.whiteColor().setFill()
        backgroundRect.fill()
        
        if self.attachedFiles?.count >= 1 {
            // Render our text, and the first attachment
            let attachmentImage = self.attachedFiles?[0].thumbnailImage
            
            var firstHalf : CGRect = CGRectZero
            var secondHalf : CGRect = CGRectZero
            
            CGRectDivide(entireImageRect, &firstHalf, &secondHalf, entireImageRect.size.height / 2.0, CGRectEdge.MinYEdge)
            
            self.text.drawInRect(firstHalf)
            attachmentImage?.drawInRect(secondHalf)
        } else {
            // Just render our text
            self.text.drawInRect(entireImageRect)
        }
        
        let bitmapRepresentation = NSBitmapImageRep(focusedViewRect: entireImageRect)
        
        image.unlockFocus()
        
        // Convert it to a PNG
        return bitmapRepresentation?.representationUsingType(.NSPNGFileType, properties: [:])
        
    }
    // END document_icon_data
}


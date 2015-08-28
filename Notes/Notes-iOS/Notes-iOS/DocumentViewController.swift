//
//  DocumentViewController.swift
//  Notes
//
//  Created by Jonathon Manning on 26/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreSpotlight

class DocumentViewController: UIViewController, UITextViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var attachmentsCollectionView : UICollectionView?
    
    @IBOutlet weak var textView : UITextView?
    
    private var shouldCloseOnDisappear = true
    
    private var document : Document?
    
    private var isEditingAttachments = false
    
    func textViewDidChange(textView: UITextView) {
        document?.text = textView.attributedText
        document?.updateChangeCount(.Done)
    }
    
    // The location of the document we're showing
    var documentURL:NSURL? {
        // When it's set, create a new document object for us to open
        didSet {
            if let url = documentURL {
                self.document = Document(fileURL:url)
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        // Ensure that we actually have a document
        guard let document = self.document else {
            NSLog("No document to display!")
            self.navigationController?.popViewControllerAnimated(true)
            return
        }
        
        // If this document is not already open, open it
        if document.documentState.contains(UIDocumentState.Closed) {
            document.openWithCompletionHandler { (success) -> Void in
                if success == true {
                    self.textView?.attributedText = document.text
                    
                    self.attachmentsCollectionView?.reloadData()
                    
                    
                    // Add support for searching
                    document.userActivity?.title = document.localizedName
                    
                    let contentAttributeSet = CSSearchableItemAttributeSet(itemContentType: document.fileType!)
                    contentAttributeSet.title = document.localizedName
                    contentAttributeSet.contentDescription = document.text.string
                    
                    document.userActivity?.contentAttributeSet = contentAttributeSet

                    document.userActivity?.eligibleForSearch = true
                    
                    // We are now engaged in this activity
                    document.userActivity?.becomeCurrent()
                    
                    
                    
                } else {
                    
                    // We can't open it! Show an alert!
                    let alertTitle = "Error"
                    let alertMessage = "Failed to open document"
                    let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
                    
                    // Add a button that returns to the previous screen
                    alert.addAction(UIAlertAction(title: "Close", style: .Default, handler: { (action) -> Void in
                        self.navigationController?.popViewControllerAnimated(true)
                    }))
                    
                    // Show the alert
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
        
        // We may be re-appearing after having presented an attachment,
        // which means that our 'don't close on disappear' flag has been set.
        // Regardless, clear that flag.
        self.shouldCloseOnDisappear = true
        
        // And re-load our list of attachments, in case it changed while we were away
        self.attachmentsCollectionView?.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        if shouldCloseOnDisappear {
            self.document?.closeWithCompletionHandler(nil)
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // No cells if the document is closed or if it doesn't exist
        if self.document!.documentState.contains(.Closed) {
            return 0
        }
        
        // Return as many cells as we have, plus the add cell
        return (self.document?.attachedFiles?.count ?? 0) + 1
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let totalNumberOfCells = collectionView.numberOfItemsInSection(indexPath.section)
        
        let isAddCell = indexPath.row == (totalNumberOfCells - 1)
        
        let cell : UICollectionViewCell
        
        if isAddCell {
            cell = collectionView.dequeueReusableCellWithReuseIdentifier("AddAttachmentCell", forIndexPath: indexPath)
        } else {
            
            // Get the cell
            let attachmentCell = collectionView.dequeueReusableCellWithReuseIdentifier("AttachmentCell", forIndexPath: indexPath) as! AttachmentCell
            
            // Get a thumbnail image for the attachment
            let attachment = self.document?.attachedFiles?[indexPath.row]
            let image = attachment?.thumbnailImage()
            
            // Give it to the cell
            attachmentCell.imageView?.image = image
            
            // Add a long-press gesture to it, if it doesn't
            // already have it
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: "beginEditMode")
            attachmentCell.gestureRecognizers = [longPressGesture]
            
            // The cell should be in edit mode if the view controller is
            attachmentCell.editMode = isEditingAttachments
            
            // Contact us when the user taps the delete button
            attachmentCell.delegate = self
            
            // Use this cell
            cell = attachmentCell
        }
        
        return cell
        
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // Do nothing if we are editing
        if self.isEditingAttachments {
            return
        }
        
        // Work out how many cells we have
        let totalNumberOfCells = collectionView.numberOfItemsInSection(indexPath.section)
        
        let selectedCell = collectionView.cellForItemAtIndexPath(indexPath)
        
        // If we have selected the last cell, show the Add screen
        if indexPath.row == totalNumberOfCells-1 {
            self.performSegueWithIdentifier("ShowAddAttachment", sender: selectedCell)
        } else {
            // Otherwise, show a different view controller based on the type
            // of the attachment
            if let attachment = self.document?.attachedFiles?[indexPath.row] {
                
                let segueName : String?
                
                if attachment.conformsToType(kUTTypeImage) {
                    segueName = "ShowImageAttachment"
                } else if attachment.conformsToType(kUTTypeJSON) {
                    segueName = "ShowLocationAttachment"
                } else {
                    // We have no view controller for this. Instead,
                    // show a UIDocumentInteractionController
                    
                    self.document?.URLForAttachment(attachment, completion: { (url) -> Void in
                        
                        if let url = url, cell = selectedCell {
                            let documentInteraction = UIDocumentInteractionController(URL: url)
                            
                            documentInteraction.presentOptionsMenuFromRect(cell.bounds, inView: cell, animated: true)
                        }
                        
                    })
                    
                    
                    
                    segueName = nil
                }
                
                if let theSegue = segueName {
                    self.performSegueWithIdentifier(theSegue, sender: selectedCell)
                }
                
            }
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // If it's ShowAddAttachment, and the sender was a UICollectionViewCell, and we're doing it in a popover, and we're heading to an AddAttachmentViewController..
        if segue.identifier == "ShowAddAttachment", let cell = sender as? UICollectionViewCell, let popover = segue.destinationViewController.popoverPresentationController, let addAttachmentViewController = segue.destinationViewController as? AddAttachmentViewController {
            
            // Don't close the document when we disappear
            self.shouldCloseOnDisappear = false
            
            // Display the popover from here
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
            
            // Part of the solution to the problem of no close button on iPhone
            popover.delegate = self
            
            // Receive instructions to add attachments
            addAttachmentViewController.delegate = self
            
        }
        
        // If we're going to an AttachmentViewer...
        if let attachmentViewer = segue.destinationViewController as? AttachmentViewer {
            
            attachmentViewer.document = self.document!
            
            // If we were coming from a cell, get the attachment
            // that this cell represents so that we can view it
            if let cell = sender as? UICollectionViewCell, let indexPath = self.attachmentsCollectionView?.indexPathForCell(cell), let attachment = self.document?.attachedFiles?[indexPath.row] {
                
                attachmentViewer.attachmentFile = attachment
            }
            
            // Don't close the document when showing the view controller
            self.shouldCloseOnDisappear = false
            
            // Ensure that we add a close button to the popover on iPhone
            segue.destinationViewController.popoverPresentationController?.delegate = self
            
            
        }
        
    }
}

// This extension adds a navigation controller that contains a "Done" button to view controllers that are being presented in a popover, but that popover is appearing in full-screen mode
extension DocumentViewController : UIPopoverPresentationControllerDelegate {
    
    // Called by the system to determine which view controller should be the content of the popover
    func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        
        // Get the view controller that we want to present
        let presentedViewController = controller.presentedViewController
        
        // If we're showing a popover, and that popover is being shown
        // as a full-screen modal (which happens on iPhone)..
        if style == UIModalPresentationStyle.FullScreen && controller is UIPopoverPresentationController {
            
            // Create a navigation controller that contains the content
            let navigationController = UINavigationController(rootViewController: controller.presentedViewController)
            
            // Create and set up a "Done" button, and add it to the navigation controller
            let closeButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: "dismissModalView")
            
            presentedViewController.navigationItem.rightBarButtonItem = closeButton
            
            // Tell the system that the content should be this new navigation controller
            return navigationController
        } else {
            
            // Just return the content
            return presentedViewController
        }
    }
    
    func dismissModalView() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

class AttachmentCell : UICollectionViewCell {
    @IBOutlet weak var imageView : UIImageView?
    
    @IBOutlet weak var deleteButton : UIButton?
    
    var editMode = false {
        didSet {
            // Full alpha if we're editing, zero if we're not
            deleteButton?.alpha = editMode ? 1 : 0
        }
    }
    
    var delegate : AttachmentCellDelegate?
    
    @IBAction func delete() {
        self.delegate?.attachmentCellWasDeleted(self)
    }
}

protocol AttachmentCellDelegate {
    func attachmentCellWasDeleted(cell: AttachmentCell)
}

extension DocumentViewController : AttachmentCellDelegate {
    func attachmentCellWasDeleted(cell: AttachmentCell) {
        guard let indexPath = self.attachmentsCollectionView?.indexPathForCell(cell) else {
            return
        }
        
        guard let attachment = self.document?.attachedFiles?[indexPath.row] else {
            return
        }
        do {
            try self.document?.deleteAttachment(attachment)
            
            self.attachmentsCollectionView?.deleteItemsAtIndexPaths([indexPath])
            
            self.endEditMode()
        } catch let error as NSError {
            NSLog("Failed to delete attachment: \(error)")
        }
        
    }
}

extension DocumentViewController : AddAttachmentDelegate {
    func addPhoto() {
        let picker = UIImagePickerController()
        picker.delegate = self
        self.shouldCloseOnDisappear = false
        self.presentViewController(picker, animated: true, completion: nil)
    }
    
    func addLocation() {
        self.performSegueWithIdentifier("ShowLocationAttachment", sender: nil)
    }
}

extension DocumentViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        let imageToUse = info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]
        
        if let image = imageToUse as? UIImage,
            let imageData = UIImageJPEGRepresentation(image, 0.8) {
            
                do {
                    try self.document?.addAttachmentWithData(imageData, name: "Image \(arc4random()).jpg")
                    
                    self.attachmentsCollectionView?.reloadData()
                    
                } catch let error as NSError {
                    NSLog("Error adding attachment: \(error)")
                }
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    
}

// The protocol inherits from NSObejctProtocol to ensure that Swift
// realises that any AttachmentView must be a class and not a struct
protocol AttachmentViewer : NSObjectProtocol {
    
    // The attachment to view. If this is nil, 
    // the viewer should instead attempt to create a new
    // attachment, if applicable.
    var attachmentFile : NSFileWrapper? { get set }
    
    // The document attached to this file
    var document : Document? { get set }
}

// Attachment editing
extension DocumentViewController {
    
    @IBAction func beginEditMode() {
        
        self.isEditingAttachments = true
        
        UIView.animateWithDuration(0.1) { () -> Void in
            for cell in self.attachmentsCollectionView!.visibleCells() {
                
                if let attachmentCell = cell as? AttachmentCell {
                    attachmentCell.editMode = true
                } else  {
                    cell.alpha = 0
                }
                
            }
        }
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "endEditMode")
        self.navigationItem.rightBarButtonItem = doneButton
        
    }
    
    func endEditMode() {
        
        self.isEditingAttachments = false
        
        UIView.animateWithDuration(0.1) { () -> Void in
            for cell in self.attachmentsCollectionView!.visibleCells() {
                
                if let attachmentCell = cell as? AttachmentCell {
                    attachmentCell.editMode = false
                } else {
                    cell.alpha = 1
                }
            }
        }
        
        self.navigationItem.rightBarButtonItem = nil
    }
}
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

// MARK: Base document support

// BEGIN text_view_delegate
class DocumentViewController: UIViewController, UITextViewDelegate {
// END text_view_delegate
    
    
    // BEGIN base_properties
    @IBOutlet weak var textView : UITextView?
    
    private var document : Document?
    
    // The location of the document we're showing
    var documentURL:NSURL? {
        // When it's set, create a new document object for us to open
        didSet {
            if let url = documentURL {
                self.document = Document(fileURL:url)
            }
        }
    }
    // END base_properties

    // BEGIN attachments_collection_view
    @IBOutlet weak var attachmentsCollectionView : UICollectionView?
    // END attachments_collection_view

    // BEGIN attachments_close_support_property
    private var shouldCloseOnDisappear = true
    // END attachments_close_support_property
    
    
    // BEGIN attachments_editing_attachments_property
    private var isEditingAttachments = false
    // END attachments_editing_attachments_property
    
    // BEGIN text_view_did_change
    func textViewDidChange(textView: UITextView) {
        document?.text = textView.attributedText
        document?.updateChangeCount(.Done)
    }
    // END text_view_did_change
    
    // BEGIN view_will_appear
    override func viewWillAppear(animated: Bool) {
        // Ensure that we actually have a document
        guard let document = self.document else {
            NSLog("No document to display!")
            self.navigationController?.popViewControllerAnimated(true)
            return
        }
        
        // BEGIN view_will_appear_opening
        // If this document is not already open, open it
        if document.documentState.contains(UIDocumentState.Closed) {
            document.openWithCompletionHandler { (success) -> Void in
                if success == true {
                    self.textView?.attributedText = document.text
                    
                    // BEGIN view_will_appear_attachment_support
                    self.attachmentsCollectionView?.reloadData()
                    // END view_will_appear_attachment_support
                    
                    // BEGIN view_will_appear_searching_support
                    // Add support for searching
                    document.userActivity?.title = document.localizedName
                    
                    let contentAttributeSet = CSSearchableItemAttributeSet(itemContentType: document.fileType!)
                    contentAttributeSet.title = document.localizedName
                    contentAttributeSet.contentDescription = document.text.string
                    
                    document.userActivity?.contentAttributeSet = contentAttributeSet

                    document.userActivity?.eligibleForSearch = true
                    
                    // We are now engaged in this activity
                    document.userActivity?.becomeCurrent()
                    // END view_will_appear_searching_support
                    
                } else {
        // END view_will_appear_opening
                    
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
        
        // BEGIN view_will_appear_attachment_support
        // We may be re-appearing after having presented an attachment,
        // which means that our 'don't close on disappear' flag has been set.
        // Regardless, clear that flag.
        self.shouldCloseOnDisappear = true
        
        // And re-load our list of attachments, in case it changed while we were away
        self.attachmentsCollectionView?.reloadData()
        // END view_will_appear_attachment_support
    }
    // END view_will_appear
    
    // BEGIN view_will_disappear
    override func viewWillDisappear(animated: Bool) {
        
        // BEGIN view_will_disapper_conditional_closing
        if shouldCloseOnDisappear == false {
            return
        }
        // END view_will_disapper_conditional_closing
        
        self.document?.closeWithCompletionHandler(nil)
    }
    // END view_will_disappear
    

    // BEGIN prepare_for_segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // If it's ShowAddAttachment, and the sender was a UICollectionViewCell, 
        // and we're doing it in a popover, and we're heading to an
        // AddAttachmentViewController..
        if segue.identifier == "ShowAddAttachment",
            let cell = sender as? UICollectionViewCell,
            let popover = segue.destinationViewController.popoverPresentationController,
            let addAttachmentViewController =
                segue.destinationViewController as? AddAttachmentViewController
        {
            // BEGIN prepare_for_segue_close_on_disappear
            // Don't close the document when we disappear
            self.shouldCloseOnDisappear = false
            // END prepare_for_segue_close_on_disappear
            
            // Display the popover from here
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
            
            // BEGIN prepare_for_segue_popover_delegate
            // Tell the popover to consult us about how to present
            // this view (we'll need to change it on iPhone)
            popover.delegate = self
            // END prepare_for_segue_popover_delegate
            
            // BEGIN prepare_for_segue_popover_attachment_delegate
            // Receive instructions to add attachments
            addAttachmentViewController.delegate = self
            // END prepare_for_segue_popover_attachment_delegate
        }
        
        // BEGIN prepare_for_segue_attachments
        // If we're going to an AttachmentViewer...
        if let attachmentViewer = segue.destinationViewController as? AttachmentViewer {
            
            // Give the attachment viewer our document
            attachmentViewer.document = self.document!
            
            // If we were coming from a cell, get the attachment
            // that this cell represents so that we can view it
            if let cell = sender as? UICollectionViewCell,
                let indexPath = self.attachmentsCollectionView?.indexPathForCell(cell),
                let attachment = self.document?.attachedFiles?[indexPath.row] {
                
                attachmentViewer.attachmentFile = attachment
            }
            
            // Don't close the document when showing the view controller
            self.shouldCloseOnDisappear = false
            
            // Ensure that we add a close button to the popover on iPhone
            segue.destinationViewController.popoverPresentationController?.delegate = self
        }
        // END prepare_for_segue_attachments
        
    }
    // END prepare_for_segue
}

// MARK: - Collection view
// BEGIN document_vc_collectionview
extension DocumentViewController : UICollectionViewDataSource, UICollectionViewDelegate {
    
    // BEGIN document_vc_numberofitems
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // No cells if the document is closed or if it doesn't exist
        if self.document!.documentState.contains(.Closed) {
            return 0
        }
        
        guard let attachments = self.document?.attachedFiles else {
            // No cells if we can't access the attached files list
            return 0
        }
        
        // Return as many cells as we have, plus the add cell
        return attachments.count + 1
    }
    // END document_vc_numberofitems
    
    // BEGIN document_vc_cellforitem
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // Work out how many cells we need to display
        let totalNumberOfCells = collectionView.numberOfItemsInSection(indexPath.section)
        
        // Figure out if we're being asked to configure the Add cell,
        // or any other cell. If we're the last cell, it's the Add cell.
        let isAddCell = (indexPath.row == (totalNumberOfCells - 1))
        
        // The place to store the cell. By making it 'let', we're ensuring
        // that we never accidentally fail to give it a value - the compiler will call us out.
        let cell : UICollectionViewCell
        
        // Create and return the 'Add' cell if we need to
        if isAddCell {
            cell = collectionView.dequeueReusableCellWithReuseIdentifier("AddAttachmentCell", forIndexPath: indexPath)
        } else {
            
            // This is a regular attachment cell
            
            // Get the cell
            let attachmentCell = collectionView.dequeueReusableCellWithReuseIdentifier("AttachmentCell", forIndexPath: indexPath) as! AttachmentCell
            
            // Get a thumbnail image for the attachment
            let attachment = self.document?.attachedFiles?[indexPath.row]
            let image = attachment?.thumbnailImage()
            
            // Give it to the cell
            attachmentCell.imageView?.image = image
            
            // BEGIN document_vc_cellforitem_editsupport
            
            // The cell should be in edit mode if the view controller is
            attachmentCell.editMode = isEditingAttachments
            
            // BEGIN document_vc_cellforitem_editsupport_deletesupport
            // Add a long-press gesture to it, if it doesn't
            // already have it
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: "beginEditMode")
            attachmentCell.gestureRecognizers = [longPressGesture]
            
            // BEGIN document_vc_cellforitem_editsupport_deletesupport_delegate
            // Contact us when the user taps the delete button
            attachmentCell.delegate = self
            // END document_vc_cellforitem_editsupport_deletesupport_delegate
            // END document_vc_cellforitem_editsupport_deletesupport
            // END document_vc_cellforitem_editsupport
            
            // Use this cell
            cell = attachmentCell
        }
        
        return cell
        
    }
    // END document_vc_cellforitem

    // BEGIN document_vc_didselectitem
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // BEGIN document_vc_didselectitem_edit_support
        // Do nothing if we are editing
        if self.isEditingAttachments {
            return
        }
        // END document_vc_didselectitem_edit_support

        // Work out how many cells we have
        let totalNumberOfCells = collectionView.numberOfItemsInSection(indexPath.section)
        
        let selectedCell = collectionView.cellForItemAtIndexPath(indexPath)
        
        // If we have selected the last cell, show the Add screen
        if indexPath.row == totalNumberOfCells-1 {
            self.performSegueWithIdentifier("ShowAddAttachment", sender: selectedCell)
        }
        // BEGIN document_vc_didselectitem_attachments
        else {
            // Otherwise, show a different view controller based on the type
            // of the attachment
            if let attachment = self.document?.attachedFiles?[indexPath.row] {
                
                let segueName : String?
                
                if attachment.conformsToType(kUTTypeImage) {
                    segueName = "ShowImageAttachment"
                    
                // BEGIN document_vc_didselectitem_attachments_location
                } else if attachment.conformsToType(kUTTypeJSON) {
                    segueName = "ShowLocationAttachment"
                // END document_vc_didselectitem_attachments_location
                } else {
                    
                    // We have no view controller for this. 
                    // BEGIN document_vc_didselectitem_attachments_location_documentcontroller
                    // Instead, show a UIDocumentInteractionController
                    
                    self.document?.URLForAttachment(attachment, completion: { (url) -> Void in
                        
                        if let url = url, cell = selectedCell {
                            let documentInteraction = UIDocumentInteractionController(URL: url)
                            
                            documentInteraction.presentOptionsMenuFromRect(cell.bounds, inView: cell, animated: true)
                        }
                        
                    })
                    // END document_vc_didselectitem_attachments_location_documentcontroller
                    
                    segueName = nil
                }
                
                // If we have a segue, run it now
                if let theSegue = segueName {
                    self.performSegueWithIdentifier(theSegue, sender: selectedCell)
                }
            }
        }
        // END document_vc_didselectitem_attachments
    }
    // END document_vc_didselectitem
    
}
// END document_vc_collectionview


// This extension adds a navigation controller that contains a "Done" button to view controllers that are being presented in a popover, but that popover is appearing in full-screen mode
// BEGIN document_view_controller_popover_management
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
            // It will call the 'dismissModalView' button, below
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
// END document_view_controller_popover_management

// BEGIN attachment_cell
class AttachmentCell : UICollectionViewCell {
    
    @IBOutlet weak var imageView : UIImageView?
    
    // BEGIN attachment_cell_edit_support
    @IBOutlet weak var deleteButton : UIButton?
    
    var editMode = false {
        didSet {
            // Full alpha if we're editing, zero if we're not
            deleteButton?.alpha = editMode ? 1 : 0
        }
    }
    
    // BEGIN attachment_cell_delete_support_delegate
    var delegate : AttachmentCellDelegate?
    // END attachment_cell_delete_support_delegate
    
    // BEGIN attachment_cell_delete_support_deletemethod
    @IBAction func delete() {
        self.delegate?.attachmentCellWasDeleted(self)
    }
    // END attachment_cell_delete_support_deletemethod
    
    // END attachment_cell_edit_support

}
// END attachment_cell

// BEGIN attachment_cell_delegate
protocol AttachmentCellDelegate {
    func attachmentCellWasDeleted(cell: AttachmentCell)
}
// END attachment_cell_delegate

// BEGIN document_view_controller_attachment_cell_delegate_impl
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
// END document_view_controller_attachment_cell_delegate_impl

// BEGIN document_add_attachment_delegate_implementation
extension DocumentViewController : AddAttachmentDelegate {
    
    // BEGIN document_add_attachment_delegate_implementation_photo
    func addPhoto() {
        // BEGIN document_add_attachment_delegate_implementation_photo_impl
        let picker = UIImagePickerController()
        picker.delegate = self
        
        // BEGIN document_add_attachment_delegate_implementation_photo_impl_close_on_disappear
        self.shouldCloseOnDisappear = false
        // END document_add_attachment_delegate_implementation_photo_impl_close_on_disappear
        
        self.presentViewController(picker, animated: true, completion: nil)
        // END document_add_attachment_delegate_implementation_photo_impl
    }
    // END document_add_attachment_delegate_implementation_photo
    
    // BEGIN document_add_attachment_delegate_implementation_location
    func addLocation() {
        self.performSegueWithIdentifier("ShowLocationAttachment", sender: nil)
    }
    // END document_add_attachment_delegate_implementation_location
    
}
// END document_add_attachment_delegate_implementation

// BEGIN document_image_controller_support
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
// END document_image_controller_support

// The protocol inherits from NSObjectProtocol to ensure that Swift
// realises that any AttachmentView must be a class and not a struct

// BEGIN attachment_viewer_protocol
protocol AttachmentViewer : NSObjectProtocol {
    
    // The attachment to view. If this is nil, 
    // the viewer should instead attempt to create a new
    // attachment, if applicable.
    var attachmentFile : NSFileWrapper? { get set }
    
    // The document attached to this file
    var document : Document? { get set }
}
// END attachment_viewer_protocol

// Attachment editing
extension DocumentViewController {
    
    // BEGIN begin_edit_mode
    func beginEditMode() {
        
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
    // END begin_edit_mode
    
    // BEGIN end_edit_mode
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
    // END end_edit_mode
}
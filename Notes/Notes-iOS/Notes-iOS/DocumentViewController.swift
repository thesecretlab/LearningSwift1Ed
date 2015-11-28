//
//  DocumentViewController.swift
//  Notes
//
//  Created by Jonathon Manning on 26/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import UIKit
import MobileCoreServices

// BEGIN core_spotlight
import CoreSpotlight
// END core_spotlight


// BEGIN import_avkit
import AVKit
// END import_avkit

import AVFoundation

// BEGIN safari_services
import SafariServices
// END safari_services

// BEGIN contacts_frameworks
import Contacts
import ContactsUI
// END contacts_frameworks

// MARK: Base document support

// BEGIN text_view_delegate
class DocumentViewController: UIViewController, UITextViewDelegate {
// END text_view_delegate
    
    
    // BEGIN base_properties
    @IBOutlet weak var textView : UITextView!
    
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
    
    var beginEditingButton = UIBarButtonItem(barButtonSystemItem: .Edit, target: nil, action: nil)
    var endEditingButton = UIBarButtonItem(barButtonSystemItem: .Done, target: nil, action: nil)

    // BEGIN attachments_collection_view
    @IBOutlet weak var attachmentsCollectionView : UICollectionView!
    // END attachments_collection_view

    // BEGIN attachments_close_support_property
    private var shouldCloseOnDisappear = true
    // END attachments_close_support_property
    
    
    // BEGIN attachments_editing_attachments_property
    private var isEditingAttachments = false
    // END attachments_editing_attachments_property
    
    // BEGIN text_view_did_change
    func textViewDidChange(textView: UITextView) {
        
        // BEGIN text_view_did_change_undo_support
        self.undoButton?.enabled = self.textView.undoManager?.canUndo == true
        // END text_view_did_change_undo_support
        
        document?.text = textView.attributedText
        document?.updateChangeCount(.Done)
    }
    // END text_view_did_change
    
    // Undo support
    // BEGIN undo_properties
    var undoButton : UIBarButtonItem?
    var didUndoObserver : AnyObject?
    var didRedoObserver : AnyObject?
    // END undo_properties
    
    // State change support
    // BEGIN state_changed_observer
    var stateChangedObserver : AnyObject?
    // END state_changed_observer
    
    
    // BEGIN document_vc_view_did_load
    override func viewDidLoad() {
        
        let menuController = UIMenuController.sharedMenuController()
        let speakItem = UIMenuItem(title: "Speak", action: "speakSelection:")
        menuController.menuItems = [speakItem]
        
        // BEGIN document_vc_view_did_load_edit_support
        /*- (means that the snippet parser will ignore this line)
        self.editing = false
        -*/ // likewise this line
        // END document_vc_view_did_load_edit_support
        
        // BEGIN document_vc_view_did_load_prefs
        self.editing = NSUserDefaults.standardUserDefaults().boolForKey("document_edit_on_open")
        // END document_vc_view_did_load_prefs
        
        // BEGIN document_vc_view_did_load_undo_support
        let respondToUndoOrRedo = { (notification:NSNotification) -> Void in
            self.undoButton?.enabled = self.textView.undoManager?.canUndo == true
        }
        
        didUndoObserver = NSNotificationCenter.defaultCenter().addObserverForName(NSUndoManagerDidUndoChangeNotification, object: nil, queue: nil, usingBlock: respondToUndoOrRedo)
        didRedoObserver = NSNotificationCenter.defaultCenter().addObserverForName(NSUndoManagerDidRedoChangeNotification, object: nil, queue: nil, usingBlock: respondToUndoOrRedo)
        
        // END document_vc_view_did_load_undo_support
        
        
    }
    // END document_vc_view_did_load
    
    
    // BEGIN document_vc_set_editing
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        self.textView.editable = editing
        
        if editing {
            // If we are now editing, make the text view take
            // focus and display the keyboard
            self.textView.becomeFirstResponder()
        }
        
        updateBarItems()
    }
    // END document_vc_set_editing
    
    
    // BEGIN speech_synthesizer
    let speechSynthesizer = AVSpeechSynthesizer()
    // END speech_synthesizer
    
    // BEGIN speak_selection
    func speakSelection(sender:AnyObject) {
        
        self.textView.selectedTextRange?.start
        
        if let range = self.textView.selectedTextRange,
            let selectedText = self.textView.textInRange(range) {

            let utterance = AVSpeechUtterance(string: selectedText)
            speechSynthesizer.speakUtterance(utterance)
        }
    }
    // END speak_selection
    
    // BEGIN document_vc_link_tapping
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL,
        inRange characterRange: NSRange) -> Bool {
        
        let safari = SFSafariViewController(URL: URL)
        self.presentViewController(safari, animated: true, completion: nil)
        
        // return false to not launch in Safari
        return false
    }
    // END document_vc_link_tapping
    
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
                    // Add support for searching for this document
                    document.userActivity?.title = document.localizedName
                    
                    let contentAttributeSet
                        = CSSearchableItemAttributeSet(itemContentType: document.fileType!)
                    contentAttributeSet.title = document.localizedName
                    contentAttributeSet.contentDescription = document.text.string
                    
                    document.userActivity?.contentAttributeSet = contentAttributeSet

                    document.userActivity?.eligibleForSearch = true
                    // END view_will_appear_searching_support

                    // BEGIN view_will_appear_handoff_support
                    // We are now engaged in this activity
                    document.userActivity?.becomeCurrent()
                    // END view_will_appear_handoff_support
                    
                    // BEGIN view_will_appear_state_change_support
                    // Register for state change notifications
                    self.stateChangedObserver = NSNotificationCenter
                        .defaultCenter().addObserverForName(
                            UIDocumentStateChangedNotification,
                            object: document,
                            queue: nil,
                            usingBlock: { (notification) -> Void in
                            self.documentStateChanged()
                        })
                    
                    self.documentStateChanged()
                    // END view_will_appear_state_change_support
                    
                    // BEGIN view_will_appear_update_bar_items
                    self.updateBarItems()
                    // END view_will_appear_update_bar_items
                    
                }
        // END view_will_appear_opening
                else
                {
                    // We can't open it! Show an alert!
                    let alertTitle = "Error"
                    let alertMessage = "Failed to open document"
                    let alert = UIAlertController(title: alertTitle,
                        message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
                    
                    // Add a button that returns to the previous screen
                    alert.addAction(UIAlertAction(title: "Close",
                        style: .Default, handler: { (action) -> Void in
                        self.navigationController?.popViewControllerAnimated(true)
                    }))
                    
                    // Show the alert
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
        
        // BEGIN view_will_appear_dont_close_on_opening_attachments
        // We may be re-appearing after having presented an attachment,
        // which means that our 'don't close on disappear' flag has been set.
        // Regardless, clear that flag.
        self.shouldCloseOnDisappear = true
        
        // BEGIN view_will_appear_dont_close_on_opening_attachments_list
        // And re-load our list of attachments, in case it changed 
        // while we were away
        self.attachmentsCollectionView?.reloadData()
        // END view_will_appear_dont_close_on_opening_attachments_list
        // END view_will_appear_dont_close_on_opening_attachments
        
        // BEGIN view_will_appear_update_bar_items_2
        // Also, refresh the contents of the navigation bar
        updateBarItems()
        // END view_will_appear_update_bar_items_2
        
    }
    // END view_will_appear
    
    // BEGIN document_state_changed
    func documentStateChanged() {
        if let document = self.document where document.documentState.contains(UIDocumentState.InConflict) {
            // Gather all conflicted versions
            guard var conflictedVersions = NSFileVersion
                .unresolvedConflictVersionsOfItemAtURL(document.fileURL) else {
                fatalError("The document is in conflict, but no " +
                    "conflicting versions were found. This should not happen.")
            }
            let currentVersion = NSFileVersion.currentVersionOfItemAtURL(document.fileURL)!
            // And include our own local version
            conflictedVersions += [currentVersion]
            
            // Prepare a chooser
            let title = "Resolve conflicts"
            let message = "Choose a version of this document to keep."
            
            let picker = UIAlertController(title: title, message: message,
                preferredStyle: UIAlertControllerStyle.ActionSheet);
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .ShortStyle
            dateFormatter.timeStyle = .ShortStyle
            
            // We'll use this multiple times, so save it as a variable
            let cancelAndClose = { (action:UIAlertAction) -> Void in
                // Give up and return
                self.navigationController?.popViewControllerAnimated(true)
            }
            
            // For each version, offer it as an option
            for version in conflictedVersions {
                let description = "Edited on \(version.localizedNameOfSavingComputer!) at \(dateFormatter.stringFromDate(version.modificationDate!))"
                
                let action = UIAlertAction(title: description, style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                    
                    // If it was selected, use this version
                    do {
                        
                        if version != currentVersion {
                            try version.replaceItemAtURL(document.fileURL, options: NSFileVersionReplacingOptions.ByMoving)
                            try NSFileVersion.removeOtherVersionsOfItemAtURL(document.fileURL)
                        }
                        
                        // BEGIN document_state_changed_bar_items_context
                        
                        document.revertToContentsOfURL(document.fileURL, completionHandler: { (success) -> Void in
                            self.textView.attributedText = document.text
                            self.attachmentsCollectionView?.reloadData()
                            
                            // BEGIN document_state_changed_bar_items
                            self.updateBarItems()
                            // END document_state_changed_bar_items
                        })
                        
                        for version in conflictedVersions{
                            version.resolved = true
                        }
                        
                        // END document_state_changed_bar_items_context
                        
                    } catch let error as NSError {
                        // If there was a problem, let the user know and close the document
                        let errorView = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                        errorView.addAction(UIAlertAction(title: "Done", style: UIAlertActionStyle.Cancel, handler: cancelAndClose))
                        self.shouldCloseOnDisappear = false
                        self.presentViewController(errorView, animated: true, completion: nil)
                    }
                
                })
                picker.addAction(action)
            }
            
            // Add a 'choose later' option
            picker.addAction(UIAlertAction(title: "Choose Later", style: UIAlertActionStyle.Cancel, handler: cancelAndClose))
            
            self.shouldCloseOnDisappear = false
            
            // Finally, show the picker
            self.presentViewController(picker, animated: true, completion: nil)
        }
    }
    // END document_state_changed
    
    // BEGIN bar_items
    func updateBarItems() {
        var rightButtonItems : [UIBarButtonItem] = []
        rightButtonItems.append(self.editButtonItem())
        
        // BEGIN bar_items_notification_button
        let notificationButtonImage : UIImage?
        if self.document?.localNotification == nil {
             notificationButtonImage = UIImage(named:"Notification-Off")
        } else {
             notificationButtonImage = UIImage(named:"Notification")
        }
        
        
        let notificationButton = UIBarButtonItem(image: notificationButtonImage, style: UIBarButtonItemStyle.Plain, target: self, action: "showNotification")
        
        rightButtonItems.append(notificationButton)
        // END bar_items_notification_button
        
        // BEGIN bar_items_undo_support
        if editing {
            undoButton = UIBarButtonItem(barButtonSystemItem: .Undo, target: self.textView?.undoManager, action: "undo")
            undoButton?.enabled = self.textView?.undoManager?.canUndo == true
            rightButtonItems.append(undoButton!)
        }
        // END bar_items_undo_support
        
        self.navigationItem.rightBarButtonItems = rightButtonItems
        
    }
    // END bar_items
    
    // BEGIN show_notification
    func showNotification() {
        self.performSegueWithIdentifier("ShowNotificationAttachment", sender: nil)
    }
    // END show_notification
    
    // BEGIN view_will_disappear
    override func viewWillDisappear(animated: Bool) {
        
        // BEGIN view_will_disapper_conditional_closing
        if shouldCloseOnDisappear == false {
            return
        }
        // END view_will_disapper_conditional_closing
        
        // BEGIN view_will_disappear_state_changed
        self.stateChangedObserver = nil
        // END view_will_disappear_state_changed
        
        self.document?.closeWithCompletionHandler(nil)
    }
    // END view_will_disappear
    

    // BEGIN prepare_for_segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // BEGIN prepare_for_segue_attachments
        // If we're going to an AttachmentViewer...
        if let attachmentViewer
            = segue.destinationViewController as? AttachmentViewer {
            
            // Give the attachment viewer our document
            attachmentViewer.document = self.document!
            
            // If we were coming from a cell, get the attachment
            // that this cell represents so that we can view it
            if let cell = sender as? UICollectionViewCell,
                let indexPath = self.attachmentsCollectionView?.indexPathForCell(cell),
                let attachment = self.document?.attachedFiles?[indexPath.row] {
                
                attachmentViewer.attachmentFile = attachment
            } else {
                // we don't have an attachment
            }
                
            // BEGIN prepare_for_segue_close_on_disappear
            // Don't close the document when showing the view controller
            self.shouldCloseOnDisappear = false
            // END prepare_for_segue_close_on_disappear
            
            // If this has a popover, present it from the the attachments list
            if let popover = segue.destinationViewController.popoverPresentationController
                {
                    
                // BEGIN prepare_for_segue_popover_delegate
                // Ensure that we add a close button to the popover on iPhone
                popover.delegate = self
                // END prepare_for_segue_popover_delegate
                
                popover.sourceView = self.attachmentsCollectionView
                popover.sourceRect = self.attachmentsCollectionView.bounds

            }
        }
        // END prepare_for_segue_attachments
        
    }
    // END prepare_for_segue
}

// MARK: - Collection view
// BEGIN document_vc_collectionview
extension DocumentViewController : UICollectionViewDataSource, UICollectionViewDelegate {
    
    // BEGIN document_vc_numberofitems
    func collectionView(collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
        
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
    func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // Work out how many cells we need to display
        let totalNumberOfCells = collectionView.numberOfItemsInSection(indexPath.section)
        
        // Figure out if we're being asked to configure the Add cell,
        // or any other cell. If we're the last cell, it's the Add cell.
        let isAddCell = (indexPath.row == (totalNumberOfCells - 1))
        
        // The place to store the cell. By making it 'let', we're ensuring
        // that we never accidentally fail to give it a value - the 
        // compiler will call us out.
        let cell : UICollectionViewCell
        
        // Create and return the 'Add' cell if we need to
        if isAddCell {
            cell = collectionView.dequeueReusableCellWithReuseIdentifier(
                "AddAttachmentCell", forIndexPath: indexPath)
        } else {
            
            // This is a regular attachment cell
            
            // Get the cell
            let attachmentCell = collectionView
                .dequeueReusableCellWithReuseIdentifier("AttachmentCell",
                    forIndexPath: indexPath) as! AttachmentCell
            
            // Get a thumbnail image for the attachment
            let attachment = self.document?.attachedFiles?[indexPath.row]
            var image = attachment?.thumbnailImage()
            
            // Give it to the cell
            if image == nil {
                // We don't know what it is, so use a generic image
                image = UIImage(named: "File")
                // Also set the label
                attachmentCell.extensionLabel?.text = attachment?.fileExtension?.uppercaseString
            } else {
                // We know what it is, so ensure that the label is empty
                attachmentCell.extensionLabel?.text = nil
            }
            attachmentCell.imageView?.image = image
            
            // BEGIN document_vc_cellforitem_editsupport
            
            // The cell should be in edit mode if the view controller is
            attachmentCell.editMode = isEditingAttachments
            
            // BEGIN document_vc_cellforitem_editsupport_deletesupport
            // Add a long-press gesture to it, if it doesn't
            // already have it
            let longPressGesture = UILongPressGestureRecognizer(target: self,
                action: "beginEditMode")
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
    
    // BEGIN add_attachment_sheet
    func addAttachment(sourceView : UIView) {
        let actionSheet = UIAlertController(title: "Add attachment", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet);

        // BEGIN add_attachment_sheet_camera
        // If a camera is available to use...
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            // This variable contains a closure that either shows the image picker,
            // or asks the user to grant permission.
            var handler : (action:UIAlertAction) -> Void
            
            
            switch AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) {
            case .Authorized:
                fallthrough
            case .NotDetermined:
                // If we have permission, or we don't know if it's been denied yet,
                // then the closure shows the image picker.
                handler = { (action) in
                    self.addPhoto()
                }
            default:
                
                // Otherwise, when the button is tapped, ask the user to grant permission.
                handler = { (action) in
                    
                    let title = "Camera access required"
                    let message = "Go to Settings to grant permission to access the camera."
                    let cancelButton = "Cancel"
                    let settingsButton = "Settings"
                    
                    let alert = UIAlertController(title: title, message: message,
                        preferredStyle: .Alert)
                    
                    // The Cancel button just closes the alert.
                    alert.addAction(UIAlertAction(title: cancelButton,
                        style: .Cancel, handler: nil))
                    
                    // The Settings button opens this app's settings page,
                    // allowing the user to grant us permission.
                    alert.addAction(UIAlertAction(title: settingsButton,
                        style: .Default, handler: { (action) in
                            
                            if let settingsURL = NSURL(string: UIApplicationOpenSettingsURLString) {
                                UIApplication.sharedApplication().openURL(settingsURL)
                            }
                            
                    }))
                    
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
            
            // Either way, show the Camera item; when it's selected, the 
            // appropriate code will run.
            actionSheet.addAction(UIAlertAction(title: "Camera",
                style: UIAlertActionStyle.Default, handler: handler))
        }
        // END add_attachment_sheet_camera
        
        // BEGIN add_attachment_sheet_location
        actionSheet.addAction(UIAlertAction(title: "Location",
            style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.addLocation()
        }))
        // END add_attachment_sheet_location
        
        // BEGIN add_attachment_sheet_audio
        actionSheet.addAction(UIAlertAction(title: "Audio",
            style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.addAudio()
        }))
        // END add_attachment_sheet_audio
        
        // BEGIN add_attachment_sheet_contact
        actionSheet.addAction(UIAlertAction(title: "Contact",
            style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.addContact()
        }))
        // END add_attachment_sheet_contact
        
        actionSheet.addAction(UIAlertAction(title: "Cancel",
            style: UIAlertActionStyle.Cancel, handler: nil))
        
        // If this is on an iPad, present it in a popover connected
        // to the source view
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Pad {
            actionSheet.modalPresentationStyle = .Popover
            actionSheet.popoverPresentationController?.sourceView = sourceView
            actionSheet.popoverPresentationController?.sourceRect = sourceView.bounds
        }
        
        self.presentViewController(actionSheet, animated: true, completion: nil)

    }
    // END add_attachment_sheet

    // BEGIN document_vc_didselectitem
    func collectionView(collectionView: UICollectionView,
        didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // BEGIN document_vc_didselectitem_edit_support
        // Do nothing if we are editing
        if self.isEditingAttachments {
            return
        }
        // END document_vc_didselectitem_edit_support

        // Work out how many cells we have
        let totalNumberOfCells = collectionView
            .numberOfItemsInSection(indexPath.section)
        
        let selectedCell = collectionView.cellForItemAtIndexPath(indexPath)
        
        // If we have selected the last cell, show the Add screen
        if indexPath.row == totalNumberOfCells-1 {
            addAttachment(selectedCell!)
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
                // BEGIN document_vc_didselectitem_attachments_audio
                } else if attachment.conformsToType(kUTTypeAudio) {
                    segueName = "ShowAudioAttachment"
                // END document_vc_didselectitem_attachments_audio
                // BEGIN document_vc_didselectitem_attachments_movie
                } else if attachment.conformsToType(kUTTypeMovie) {
                    
                    self.document?.URLForAttachment(attachment,
                        completion: { (url) -> Void in
                            
                            if let url = url {
                                let media = AVPlayerViewController()
                                media.player = AVPlayer(URL: url)
                                
                                // BEGIN document_vc_didselectitem_attachments_movie_pip_support
                                let _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                                // END document_vc_didselectitem_attachments_movie_pip_support
                                
                                self.presentViewController(media, animated: true, completion: nil)
                            }
                    })
                    
                    segueName = nil
                // END document_vc_didselectitem_attachments_movie
                // BEGIN document_vc_didselectitem_attachments_contact
                } else if attachment.conformsToType(kUTTypeContact) {
                    
                    self.document?.URLForAttachment(attachment, completion: { (url) -> Void in
                        
                        do {
                            if let contactData = NSData(contentsOfURL: url!),
                                let contact =  try CNContactVCardSerialization
                                    .contactsWithData(contactData).first as? CNContact {
                                
                                let contactViewController =
                                        CNContactViewController(forContact: contact)
                                self.presentViewController(contactViewController,
                                    animated: true, completion: nil)
                                
                            }
                        } catch let error as NSError {
                            NSLog("Error displaying contact: \(error)")
                        }
                        
                    })
                    segueName = nil
                // END document_vc_didselectitem_attachments_contact
                } else {
                    
                    // We have no view controller for this. 
                    // BEGIN document_vc_didselectitem_attachments_documentcontroller
                    // Instead, show a UIDocumentInteractionController
                    
                    self.document?.URLForAttachment(attachment,
                        completion: { (url) -> Void in
                        
                        if let url = url, cell = selectedCell {
                            let documentInteraction
                                = UIDocumentInteractionController(URL: url)
                            
                            documentInteraction
                                .presentOptionsMenuFromRect(cell.bounds,
                                    inView: cell, animated: true)
                        }
                        
                    })
                    // END document_vc_didselectitem_attachments_documentcontroller
                    
                    segueName = nil
                }
                
                // If we have a segue, run it now
                if let theSegue = segueName {
                    self.performSegueWithIdentifier(theSegue,
                        sender: selectedCell)
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
    func presentationController(controller: UIPresentationController,
        viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle)
        -> UIViewController? {
        
        // Get the view controller that we want to present
        let presentedViewController = controller.presentedViewController
        
        // If we're showing a popover, and that popover is being shown
        // as a full-screen modal (which happens on iPhone)..
        if style == UIModalPresentationStyle.FullScreen && controller
            is UIPopoverPresentationController {
            
            // Create a navigation controller that contains the content
            let navigationController = UINavigationController(rootViewController:
                controller.presentedViewController)
            
            // Create and set up a "Done" button, and add it to the 
            // navigation controller.
            // It will call the 'dismissModalView' button, below
            let closeButton = UIBarButtonItem(title: "Done",
                style: UIBarButtonItemStyle.Done, target: self,
                action: "dismissModalView")
            
            presentedViewController.navigationItem
                .rightBarButtonItem = closeButton
            
            // Tell the system that the content should be this new 
            // navigation controller.
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
    
    @IBOutlet weak var extensionLabel : UILabel?
    
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
        guard let indexPath = self.attachmentsCollectionView?
            .indexPathForCell(cell) else {
            return
        }
        
        guard let attachment = self.document?
            .attachedFiles?[indexPath.row] else {
            return
        }
        do {
            try self.document?.deleteAttachment(attachment)
            
            self.attachmentsCollectionView?
                .deleteItemsAtIndexPaths([indexPath])
            
            self.endEditMode()
        } catch let error as NSError {
            NSLog("Failed to delete attachment: \(error)")
        }
        
    }
}
// END document_view_controller_attachment_cell_delegate_impl

// BEGIN document_add_attachment_delegate_implementation
extension DocumentViewController  {
    
    // BEGIN document_add_attachment_delegate_implementation_photo
    func addPhoto() {
        // BEGIN document_add_attachment_delegate_implementation_photo_impl
        let picker = UIImagePickerController()
        picker.delegate = self
        
        
        picker.sourceType = .Camera
        // BEGIN document_add_photo_video_support
        picker.mediaTypes = UIImagePickerController.availableMediaTypesForSourceType(UIImagePickerControllerSourceType.Camera)!
        // END document_add_photo_video_support
    
        
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
    
    // BEGIN document_add_audio
    func addAudio() {
        self.performSegueWithIdentifier("ShowAudioAttachment", sender: nil)
    }
    // END document_add_audio
    
    
}
// END document_add_attachment_delegate_implementation

// BEGIN contacts_attachment
extension DocumentViewController : CNContactPickerDelegate {
    func addContact() {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        self.shouldCloseOnDisappear = false
        self.presentViewController(contactPicker, animated: true, completion: nil)
    }
    
    func contactPicker(picker: CNContactPickerViewController, didSelectContact contact: CNContact) {
        
        
        //let name = "\(contact.identifier)-\(contact.givenName)\(contact.familyName).vcf"
        let name = "\(contact.identifier)-\(contact.givenName)\(contact.familyName).vcf"
        
        do {
            if let data = try? CNContactVCardSerialization.dataWithContacts([contact]) {
                try self.document?.addAttachmentWithData(data, name: name)
                self.attachmentsCollectionView?.reloadData()                
            }
        } catch let error as NSError {
            NSLog("Failed to save contact: \(error)")
        }
    }
    
}
// END contacts_attachment

// BEGIN document_image_controller_support
extension DocumentViewController : UIImagePickerControllerDelegate,
    UINavigationControllerDelegate {
    
    // BEGIN document_image_controller_impl
    func imagePickerController(picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject]) {
            do {
                
                if let image = (info[UIImagePickerControllerEditedImage]
                    ?? info[UIImagePickerControllerOriginalImage]) as? UIImage,
                    let imageData = UIImageJPEGRepresentation(image, 0.8)  {
                        
                    try self.document?.addAttachmentWithData(imageData,
                        name: "Image \(arc4random()).jpg")
                    
                    self.attachmentsCollectionView?.reloadData()
                    
                // BEGIN document_image_controller_support_video
                } else if let mediaURL = (info[UIImagePickerControllerMediaURL]) as? NSURL {
                    
                    try self.document?.addAttachmentAtURL(mediaURL)
                // END document_image_controller_support_video
                } else {
                    throw err(.CannotSaveAttachment)
                }
            } catch let error as NSError {
                NSLog("Error adding attachment: \(error)")
            }
            
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    // END document_image_controller_impl
    
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
        
        let doneButton = UIBarButtonItem(barButtonSystemItem:
            UIBarButtonSystemItem.Done, target: self, action: "endEditMode")
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
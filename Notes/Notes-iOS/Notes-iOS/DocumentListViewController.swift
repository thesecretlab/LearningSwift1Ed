//
//  MasterViewController.swift
//  Notes-iOS
//
//  Created by Jonathon Manning on 25/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import UIKit

// BEGIN file_collection_view_cell
class FileCollectionViewCell : UICollectionViewCell {
    @IBOutlet weak var fileNameLabel : UILabel?
    
    @IBOutlet weak var imageView : UIImageView?
    
    // BEGIN file_collection_view_cell_delete_support
    @IBOutlet weak var deleteButton : UIButton?
    
    // BEGIN file_collection_view_cell_delete_support_editing
    func setEditing(editing: Bool, animated:Bool) {
        let alpha : CGFloat = editing ? 1.0 : 0.0
        if animated {
            UIView.animateWithDuration(0.25) { () -> Void in
                self.deleteButton?.alpha = alpha
            }
        } else {
            self.deleteButton?.alpha = alpha
        }
    }
    // END file_collection_view_cell_delete_support_editing
    
    // BEGIN file_collection_view_cell_delete_support_handler
    var deletionHander : (Void -> Void)?
    // END file_collection_view_cell_delete_support_handler
    
    // BEGIN file_collection_view_cell_delete_support_action
    @IBAction func deleteTapped() {
        deletionHander?()
    }
    // END file_collection_view_cell_delete_support_action
    
    // END file_collection_view_cell_delete_support
}
// END file_collection_view_cell

// BEGIN document_list_view_controller
class DocumentListViewController: UICollectionViewController {
// END document_list_view_controller
    
    // BEGIN metadata_query_properties
    var queryDidFinishGatheringObserver : AnyObject?
    var queryDidUpdateObserver: AnyObject?
    
    var metadataQuery : NSMetadataQuery = {
        let metadataQuery = NSMetadataQuery()
        metadataQuery.searchScopes =
            [NSMetadataQueryUbiquitousDocumentsScope]
        metadataQuery.predicate = NSPredicate(format: "%K LIKE '*.note'",
            NSMetadataItemFSNameKey)
        metadataQuery.sortDescriptors = [
            NSSortDescriptor(key: NSMetadataItemFSContentChangeDateKey,
                ascending: false)
        ]
        
        return metadataQuery
    }()
    // END metadata_query_properties
    
    // BEGIN file_list_property
    var availableFiles : [NSURL] = []
    // END file_list_property
    
    // BEGIN restore_user_activity_state
    override func restoreUserActivityState(activity: NSUserActivity) {
        // We're being told to open a document
        
        if let url = activity.userInfo?[NSUserActivityDocumentURLKey] as? NSURL {
            
            // Open the document
            self.performSegueWithIdentifier("ShowDocument", sender: url)
        }
        
    }
    // END restore_user_activity_state
    
    // BEGIN doc_list_view_did_load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // BEGIN doc_list_view_did_load_create
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add,
            target: self, action: "createDocument")
        self.navigationItem.rightBarButtonItem = addButton
        // END doc_list_view_did_load_create
        
        self.queryDidUpdateObserver = NSNotificationCenter.defaultCenter()
            .addObserverForName(NSMetadataQueryDidUpdateNotification,
                object: metadataQuery,
                queue: NSOperationQueue.mainQueue()) { (notification) in
                    self.queryUpdated()
        }
        self.queryDidFinishGatheringObserver = NSNotificationCenter.defaultCenter()
            .addObserverForName(NSMetadataQueryDidFinishGatheringNotification,
                object: metadataQuery,
                queue: NSOperationQueue.mainQueue()) { (notification) in
                    self.queryUpdated()
        }
        
        // BEGIN doc_list_view_did_load_edit_support
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        // END doc_list_view_did_load_edit_support
        
        metadataQuery.startQuery()
    }
    // END doc_list_view_did_load
    
    // BEGIN document_list_editing
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        for visibleCell in self.collectionView?.visibleCells() as! [FileCollectionViewCell] {
            visibleCell.setEditing(editing, animated: animated)
        }
    }
    // END document_list_editing
    
    // BEGIN query_updated
    func queryUpdated() {
        self.collectionView?.reloadData()
        
        // BEGIN query_updated_download
        
        // Bail out if, for some reason, the metadata query's results
        // can't be accessed
        guard let items = self.metadataQuery.results as? [NSMetadataItem]  else {
            return
        }
        
        availableFiles = []

        for item in items {
            
            // Ensure that we can get the file URL for this item
            guard let url =
                item.valueForAttribute(NSMetadataItemURLKey) as? NSURL else {
                // We need to have the URL to download it, so bail out
                continue
            }
            
            // Add it to the list of available files
            availableFiles.append(url)
            
            // Check to see if we already have the latest version downloaded
            if itemIsOpenable(url) == true {
                // We only need to download if it isn't already openable
                continue
            }
            
            
            // Ask the system to try to download it
            do {
                try NSFileManager.defaultManager()
                    .startDownloadingUbiquitousItemAtURL(url)
                
            } catch let error as NSError {                
                // Problem! :(
                print("Error downloading item! \(error)")
                
            }
        }
        
        // END query_updated_download

    }
    // END query_updated
    
    // MARK: - Collection View
    
    override func numberOfSectionsInCollectionView(
        collectionView: UICollectionView) -> Int {
            
        // We only ever have one section
        return 1
    }
    
    // BEGIN collection_view_datasource
    override func collectionView(collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
        
        // There are as many cells as there are items in iCloud
        return self.availableFiles.count
    }
    
    // BEGIN cellforitematindexpath
    override func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // Get our cell
        let cell = collectionView
            .dequeueReusableCellWithReuseIdentifier("FileCell",
                forIndexPath: indexPath) as! FileCollectionViewCell
        
        // BEGIN cellforitematindexpath_openable
        // We'll use this to store whether or not this is an accessible cell
        let openable : Bool
        // END cellforitematindexpath_openable
        
        // Get this object from the metadata query
        let url = availableFiles[indexPath.row]
            
        // Get the display name
        var fileName : AnyObject?
        do {
            try url.getResourceValue(&fileName, forKey: NSURLNameKey)
            if let fileName = fileName as? String {
                cell.fileNameLabel!.text = fileName
            }
        } catch {
            cell.fileNameLabel!.text = "<<error>>"
        }
            
        // Get the thumbnail image, if it exists
        let thumbnailImageURL = url.URLByAppendingPathComponent(NoteDocumentFileNames.QuickLookDirectory.rawValue , isDirectory: true).URLByAppendingPathComponent(NoteDocumentFileNames.QuickLookThumbnail.rawValue, isDirectory: false)
        
            if let path = thumbnailImageURL.path, let image = UIImage(contentsOfFile: path) {
                cell.imageView?.image = image
            } else {
                cell.imageView?.image = nil
            }
        
        
        // BEGIN cellforitematindexpath_openable
        openable = itemIsOpenable(url)
        // END cellforitematindexpath_openable
        
        // BEGIN cellforitematindexpath_editing
        cell.setEditing(self.editing, animated: false)
        cell.deletionHander = {
            self.deleteDocumentAtURL(url)
        }
        // END cellforitematindexpath_editing
        
        // BEGIN cellforitematindexpath_openable
        // If this cell is openable, make it fully visible, and
        // make the cell able to be touched
        if openable {
            cell.alpha = 1.0
            cell.userInteractionEnabled = true
        } else {
            // But if it's not, make it semitransparent, and
            // make the cell not respond to input
            cell.alpha = 0.5
            cell.userInteractionEnabled = false
        }
        // END cellforitematindexpath_openable
        
        
        return cell
        
    }
    // END cellforitematindexpath
    // END collection_view_datasource
    
    // BEGIN delete_document
    func deleteDocumentAtURL(url: NSURL) {
        
        let fileCoordinator = NSFileCoordinator(filePresenter: nil)
        fileCoordinator.coordinateWritingItemAtURL(url,
            options: .ForDeleting, error: nil) { (urlForModifying) -> Void in
            do {
                try NSFileManager.defaultManager().removeItemAtURL(urlForModifying)
                
                // Remove the URL from the list
                if let index = self.availableFiles.indexOf(url) {
                    self.availableFiles.removeAtIndex(index)
                }
                // Update the collection
                self.collectionView?.reloadData()
                
            } catch let error as NSError {
                let alert = UIAlertController(title: "Error deleting",
                    message: error.localizedDescription,
                    preferredStyle: UIAlertControllerStyle.Alert)
                
                alert.addAction(UIAlertAction(title: "Done",
                    style: .Default, handler: nil))
                
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    // END delete_document
    
    // BEGIN item_is_openable
    // Returns true if the document can be opened right now
    func itemIsOpenable(url:NSURL?) -> Bool {
        
        // Return false if item is nil
        guard let url = url else {
            return false
        }
        
        // Ask the system for the download status
        var downloadStatus : AnyObject?
        do {
            try url.getResourceValue(&downloadStatus,
                forKey: NSURLUbiquitousItemDownloadingStatusKey)
        } catch let error as NSError {
            NSLog("Failed to get downloading status for \(url): \(error)")
            // If we can't get that, we can't open it
            return false
        }
        
        // Return true if this file is the most current version
        if downloadStatus as? String == NSURLUbiquitousItemDownloadingStatusCurrent {
            return true
        } else {
            return false
        }
    }
    // END item_is_openable
    
    // BEGIN open_doc_at_path
    func openDocumentWithPath(path : String)  {
        
        // Build a file URL from this path
        let url = NSURL(fileURLWithPath: path)
        
        // Open this document
        self.performSegueWithIdentifier("ShowDocument", sender: url)
        
    }
    // END open_doc_at_path
    
    // BEGIN documents_urls
    var localDocumentsDirectoryURL : NSURL = {
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory,
            inDomains: .UserDomainMask).first!
    }()
    
    var ubiquitousDocumentsDirectoryURL : NSURL? {
        return NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(nil)?
            .URLByAppendingPathComponent("Documents")
    }
    // END documents_urls
    
    
    // BEGIN create_document
    func createDocument() {
        
        // Create a name for this new document
        let documentName = "Document \(arc4random()).note"
        
        // Work out where we're going to store it, temporarily
        let documentDestinationURL = localDocumentsDirectoryURL
            .URLByAppendingPathComponent(documentName)
        
        // Create the document and try to save it locally
        let newDocument = Document(fileURL:documentDestinationURL)
        newDocument.saveToURL(documentDestinationURL,
            forSaveOperation: .ForCreating) { (success) -> Void in
            
            // If we successfully created it, attempt to move it to iCloud
            if success == true, let ubiquitousDestinationURL =
                self.ubiquitousDocumentsDirectoryURL?
                    .URLByAppendingPathComponent(documentName) {
                
                // Perform the move to iCloud in the background
                NSOperationQueue().addOperationWithBlock { () -> Void in
                    do {
                        try NSFileManager.defaultManager()
                            .setUbiquitous(true, itemAtURL: documentDestinationURL,
                                destinationURL: ubiquitousDestinationURL)
                        
                        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                            // Open the document
                            if let path = ubiquitousDestinationURL.path {
                                self.openDocumentWithPath(path)
                            }
                        }
                    } catch let error as NSError {
                        NSLog("Error storing document in iCloud! \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    // END create_document
    
    // BEGIN did_select_item_at_index_path
    override func collectionView(collectionView: UICollectionView,
        didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // Did we select a cell that has an item that is openable?
        let selectedItem = availableFiles[indexPath.row]
            
        if itemIsOpenable(selectedItem) {
            self.performSegueWithIdentifier("ShowDocument", sender: selectedItem)
        }
        
    }
    // END did_select_item_at_index_path

    // BEGIN prepare_for_segue_list
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // If the segue is "ShowDocument" and the destination view controller is a DocumentViewController...
        if segue.identifier == "ShowDocument",
            let documentVC = segue.destinationViewController as? DocumentViewController
        {
         
            let documentURL : NSURL
            
            // If it's a metadata item and we can get the URL from it..
            if let item = sender as? NSMetadataItem,
                let url = item.valueForAttribute(NSMetadataItemURLKey) as? NSURL {
                
                documentURL = url
                
            // BEGIN prepare_for_segue_direct_url_support
            } else if let url = sender as? NSURL {
                // We've received the URL directly
                documentURL = url
            // END prepare_for_segue_direct_url_support
                
            } else {
                // it's something else, oh no!
                fatalError("ShowDocument segue was called with an " +
                    "invalid sender of type \(sender.dynamicType)")
            }
            
            // Provide the url to the view controller
            documentVC.documentURL = documentURL
        }
    }
    // END prepare_for_segue_list
    
}


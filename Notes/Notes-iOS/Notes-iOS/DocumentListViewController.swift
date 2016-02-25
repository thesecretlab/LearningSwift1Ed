//
//  MasterViewController.swift
//  Notes-iOS
//
//  Created by Jonathon Manning on 25/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import UIKit
import CoreSpotlight

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
    
    // BEGIN file_collection_view_cell_rename_support_handler
    var renameHander : (Void -> Void)?
    
    @IBAction func renameTapped() {
        renameHander?()
    }
    // END file_collection_view_cell_rename_support_handler
    
}
// END file_collection_view_cell

// BEGIN document_list_view_controller
class DocumentListViewController: UICollectionViewController {
// END document_list_view_controller
    
    // BEGIN icloud_available
    class var iCloudAvailable : Bool {
        
        if NSUserDefaults.standardUserDefaults()
            .boolForKey(NotesUseiCloudKey) == false {
            
            return false
        }
        
        return NSFileManager.defaultManager().ubiquityIdentityToken != nil
    }
    // END icloud_available
    
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
        
        // BEGIN restore_user_activity_state_watch
        // This is coming from the watch
        if let urlString = activity
                .userInfo?[WatchHandoffDocumentURL] as? String,
            let url = NSURL(string: urlString) {
                // Open the document
                self.performSegueWithIdentifier("ShowDocument", sender: url)
        }
        // END restore_user_activity_state_watch
        
        
        
        // BEGIN restore_user_activity_state_search
        // We're coming from a search result
        if let searchableItemIdentifier = activity
                .userInfo?[CSSearchableItemActivityIdentifier] as? String,
            let url = NSURL(string: searchableItemIdentifier) {
            // Open the document
            self.performSegueWithIdentifier("ShowDocument", sender: url)
        }
        // END restore_user_activity_state_search
        
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
        
        self.queryDidUpdateObserver = NSNotificationCenter
            .defaultCenter()
            .addObserverForName(NSMetadataQueryDidUpdateNotification,
                object: metadataQuery,
                queue: NSOperationQueue.mainQueue()) { (notification) in
                    self.queryUpdated()
        }
        self.queryDidFinishGatheringObserver = NSNotificationCenter
            .defaultCenter()
            .addObserverForName(NSMetadataQueryDidFinishGatheringNotification,
                object: metadataQuery,
                queue: NSOperationQueue.mainQueue()) { (notification) in
                    self.queryUpdated()
        }
        
        // BEGIN doc_list_view_did_load_edit_support
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        // END doc_list_view_did_load_edit_support
        
        // BEGIN prompt_for_icloud
        let hasPromptedForiCloud = NSUserDefaults.standardUserDefaults()
            .boolForKey(NotesHasPromptedForiCloudKey)
        
        if hasPromptedForiCloud == false {
            let alert = UIAlertController(title: "Use iCloud?",
                message: "Do you want to store your documents in iCloud, " +
                "or store them locally?",
                preferredStyle: UIAlertControllerStyle.Alert)
            
            alert.addAction(UIAlertAction(title: "iCloud",
                style: .Default,
                handler: { (action) in
                    
                NSUserDefaults.standardUserDefaults()
                    .setBool(true, forKey: NotesUseiCloudKey)
                
                self.metadataQuery.startQuery()
            }))
            
            
            alert.addAction(UIAlertAction(title: "Local Only", style: .Default,
                handler: { (action) in
                
                NSUserDefaults.standardUserDefaults()
                    .setBool(false, forKey: NotesUseiCloudKey)
                
                self.refreshLocalFileList()
            }))
            
            self.presentViewController(alert, animated: true, completion: nil)
            
            NSUserDefaults.standardUserDefaults()
                .setBool(true, forKey: NotesHasPromptedForiCloudKey)
            
        } else {
            metadataQuery.startQuery()
            refreshLocalFileList()
        }
        // END prompt_for_icloud
        
        
    }
    // END doc_list_view_did_load
    
    // BEGIN refresh_local_files
    func refreshLocalFileList() {
        
        do {
            var localFiles = try NSFileManager.defaultManager()
                .contentsOfDirectoryAtURL(
                    DocumentListViewController.localDocumentsDirectoryURL,
                    includingPropertiesForKeys: [NSURLNameKey],
                    options: [
                        .SkipsPackageDescendants,
                        .SkipsSubdirectoryDescendants
                    ]
                )
            
            localFiles = localFiles.filter({ (url) in
                return url.pathExtension == "note"
            })
            
            if (DocumentListViewController.iCloudAvailable) {
                // Move these files into iCloud
                for file in localFiles {
                    if let documentName = file.lastPathComponent,
                        let ubiquitousDestinationURL =
                        DocumentListViewController
                            .ubiquitousDocumentsDirectoryURL?
                            .URLByAppendingPathComponent(documentName) {
                                do {
                                    try NSFileManager.defaultManager()
                                        .setUbiquitous(true,
                                                       itemAtURL: file,
                                                       destinationURL:
                                                        ubiquitousDestinationURL)
                                } catch let error as NSError {
                                    NSLog("Failed to move file \(file) " +
                                        "to iCloud: \(error)")
                                }
                    }
                    
                    
                    
                }
            } else {
                // Add these files to the list of files we know about
                availableFiles.appendContentsOf(localFiles)
            }

        } catch let error as NSError {
            NSLog("Failed to list local documents: \(error)")
        }
        
    }
    // END refresh_local_files
    
    // BEGIN document_list_editing
    override func setEditing(editing: Bool, animated: Bool) {
        
        super.setEditing(editing, animated: animated)
        
        for visibleCell in self.collectionView?.visibleCells()
            as! [FileCollectionViewCell] {
                
            visibleCell.setEditing(editing, animated: animated)
        }
    }
    // END document_list_editing
    
    // BEGIN query_updated
    func queryUpdated() {
        self.collectionView?.reloadData()
        
        // Ensure that the metadata query's results can be accessed
        guard let items = self.metadataQuery.results as? [NSMetadataItem]  else {
            return
        }
        
        // Ensure that iCloud is available - if it's unavailable,
        // we shouldn't bother looking for files.
        guard DocumentListViewController.iCloudAvailable else {
            return;
        }
        
        // Clear the list of files we know about.
        availableFiles = []
        
        // Discover any local files, which don't need to be downloaded.
        refreshLocalFileList()

        for item in items {
            
            // Ensure that we can get the file URL for this item
            guard let url =
                item.valueForAttribute(NSMetadataItemURLKey) as? NSURL else {
                // We need to have the URL to access it, so move on
                // to the next file by breaking out of this loop
                continue
            }
            
            // Add it to the list of available files
            availableFiles.append(url)
            
            // BEGIN query_updated_download
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
            // END query_updated_download

        }
        
        
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
        
        
        // Get this object from the list of known files
        let url = availableFiles[indexPath.row]
            
        // Get the display name
        var fileName : AnyObject?
        do {
            try url.getResourceValue(&fileName, forKey: NSURLNameKey)
            
            if let fileName = fileName as? String {
                cell.fileNameLabel!.text = fileName
            }
        } catch {
            cell.fileNameLabel!.text = "Loading..."
        }
            
        // BEGIN cellforitematindexpath_quicklook
        // Get the thumbnail image, if it exists
        let thumbnailImageURL =
            url
                .URLByAppendingPathComponent(
                    NoteDocumentFileNames.QuickLookDirectory.rawValue,
                    isDirectory: true)
                .URLByAppendingPathComponent(
                    NoteDocumentFileNames.QuickLookThumbnail.rawValue,
                    isDirectory: false)
    
        if let path = thumbnailImageURL.path,
            let image = UIImage(contentsOfFile: path) {
            cell.imageView?.image = image
        } else {
            cell.imageView?.image = nil
        }
        // END cellforitematindexpath_quicklook
        
        // BEGIN cellforitematindexpath_editing
        cell.setEditing(self.editing, animated: false)
        cell.deletionHander = {
            self.deleteDocumentAtURL(url)
        }
        // END cellforitematindexpath_editing
            
        // BEGIN cellforitematindexpath_renaming
        
        let labelTapRecognizer = UITapGestureRecognizer(target: cell,
                                                        action: "renameTapped")
        
        cell.fileNameLabel?.gestureRecognizers = [labelTapRecognizer]
        
        cell.renameHander = {
            self.renameDocumentAtURL(url)
        }
        // END cellforitematindexpath_renaming
        
        // BEGIN cellforitematindexpath_openable
        // If this cell is openable, make it fully visible, and
        // make the cell able to be touched
        if itemIsOpenable(url) {
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
    
    // BEGIN rename_document_func
    func renameDocumentAtURL(url: NSURL) {
        
        // Create an alert box
        let renameBox = UIAlertController(title: "Rename Document",
                                          message: nil, preferredStyle: .Alert)
        
        // Add a text field to it that contains its current name, sans ".note"
        renameBox.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            let filename = url.lastPathComponent?
                .stringByReplacingOccurrencesOfString(".note", withString: "")
            textField.text = filename
        })
        
        // Add the cancel button, which does nothing
        renameBox.addAction(UIAlertAction(title: "Cancel",
            style: .Cancel, handler: nil))
        
        // Add the rename button, which actually does the renaming
        renameBox.addAction(UIAlertAction(title: "Rename",
            style: .Default) { (action) in
            
            // Attempt to construct a destination URL from 
            // the name the user provided
            if let newName = renameBox.textFields?.first?.text,
                let destinationURL = url.URLByDeletingLastPathComponent?
                    .URLByAppendingPathComponent(newName + ".note") {
                        
                        let fileCoordinator =
                            NSFileCoordinator(filePresenter: nil)
                        
                        // Indicate that we intend to do writing
                        fileCoordinator.coordinateWritingItemAtURL(url,
                            options: [],
                            writingItemAtURL: destinationURL,
                            options: [],
                            error: nil,
                            byAccessor: { (origin, destination) -> Void in
                                
                                do {
                                    // Perform the actual move
                                    try NSFileManager.defaultManager()
                                        .moveItemAtURL(origin,
                                            toURL: destination)
                                    
                                    // Remove the original URL from the file
                                    // list by filtering it out
                                    self.availableFiles =
                                        self.availableFiles.filter { $0 != url }
                                    
                                    // Add the new URL to the file list
                                    self.availableFiles.append(destination)
                                    
                                    // Refresh our collection of files
                                    self.collectionView?.reloadData()
                                } catch let error as NSError {
                                    NSLog("Failed to move \(origin) to " +
                                        "\(destination): \(error)")
                                }
                                
                        })
                        
            }
            })
        
        // Finally, present the box.
        
        self.presentViewController(renameBox, animated: true, completion: nil)
    }
    // END rename_document_func
    
    // BEGIN delete_document
    func deleteDocumentAtURL(url: NSURL) {
        
        let fileCoordinator = NSFileCoordinator(filePresenter: nil)
        fileCoordinator.coordinateWritingItemAtURL(url,
            options: .ForDeleting, error: nil) { (urlForModifying) -> Void in
            do {
                try NSFileManager.defaultManager()
                    .removeItemAtURL(urlForModifying)
                
                // Remove the URL from the list
                
                self.availableFiles = self.availableFiles.filter {
                    $0 != url
                }
                
                // Update the collection
                self.collectionView?.reloadData()
                
            } catch let error as NSError {
                let alert = UIAlertController(title: "Error deleting",
                    message: error.localizedDescription,
                    preferredStyle: UIAlertControllerStyle.Alert)
                
                alert.addAction(UIAlertAction(title: "Done",
                    style: .Default, handler: nil))
                
                self.presentViewController(alert,
                                           animated: true,
                                           completion: nil)
            }
        }
    }
    // END delete_document
    
    // BEGIN item_is_openable
    // Returns true if the document can be opened right now
    func itemIsOpenable(url:NSURL?) -> Bool {
        
        // Return false if item is nil
        guard let itemURL = url else {
            return false
        }
        
        // Return true if we don't have access to iCloud (which means
        // that it's not possible for it to be in conflict - we'll always have
        // the latest copy)
        if DocumentListViewController.iCloudAvailable == false {
            return true
        }
        
        // Ask the system for the download status
        var downloadStatus : AnyObject?
        do {
            try itemURL.getResourceValue(&downloadStatus,
                forKey: NSURLUbiquitousItemDownloadingStatusKey)
        } catch let error as NSError {
            NSLog("Failed to get downloading status for \(itemURL): \(error)")
            // If we can't get that, we can't open it
            return false
        }
        
        // Return true if this file is the most current version
        if downloadStatus as? String
            == NSURLUbiquitousItemDownloadingStatusCurrent {
            
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
    class var localDocumentsDirectoryURL : NSURL {
        return NSFileManager.defaultManager().URLsForDirectory(
            .DocumentDirectory,
            inDomains: .UserDomainMask).first!
    }
    
    class var ubiquitousDocumentsDirectoryURL : NSURL? {
        return NSFileManager.defaultManager()
            .URLForUbiquityContainerIdentifier(nil)?
            .URLByAppendingPathComponent("Documents")
    }
    // END documents_urls
    
    
    // BEGIN create_document
    func createDocument() {
        
        // Create a unique name for this new document by adding a random number
        let documentName = "Document \(arc4random()).note"
        
        // Work out where we're going to store it, temporarily
        let documentDestinationURL = DocumentListViewController
            .localDocumentsDirectoryURL
            .URLByAppendingPathComponent(documentName)
        
        // Create the document and try to save it locally
        let newDocument = Document(fileURL:documentDestinationURL)
        newDocument.saveToURL(documentDestinationURL,
            forSaveOperation: .ForCreating) { (success) -> Void in
            
            if (DocumentListViewController.iCloudAvailable) {
                
                // If we have the ability to use iCloud...
                // If we successfully created it, attempt to move it to iCloud
                if success == true, let ubiquitousDestinationURL =
                    DocumentListViewController.ubiquitousDocumentsDirectoryURL?
                        .URLByAppendingPathComponent(documentName) {
                            
                    // Perform the move to iCloud in the background
                    NSOperationQueue().addOperationWithBlock { () -> Void in
                        do {
                            try NSFileManager.defaultManager()
                                .setUbiquitous(true,
                                    itemAtURL: documentDestinationURL,
                                    destinationURL: ubiquitousDestinationURL)
                            
                            NSOperationQueue.mainQueue()
                                .addOperationWithBlock { () -> Void in
                                
                                self.availableFiles
                                    .append(ubiquitousDestinationURL)
                                
                                // BEGIN create_document_open
                                // Open the document
                                if let path = ubiquitousDestinationURL.path {
                                    self.openDocumentWithPath(path)
                                }
                                // END create_document_open
                                
                                self.collectionView?.reloadData()
                            }
                        } catch let error as NSError {
                            NSLog("Error storing document in iCloud! " +
                                "\(error.localizedDescription)")
                        }
                    }
                }
            } else {
                // We can't save it to iCloud, so it stays in local storage.
                
                self.availableFiles.append(documentDestinationURL)
                self.collectionView?.reloadData()
                
                // BEGIN create_document_open
                // Just open it locally
                if let path = documentDestinationURL.path {
                    self.openDocumentWithPath(path)
                }
                // END create_document_open
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
        
        // If the segue is "ShowDocument" and the destination view controller
        // is a DocumentViewController...
        if segue.identifier == "ShowDocument",
            let documentVC = segue.destinationViewController
                as? DocumentViewController
        {
         
            // If it's a URL we can open...
            if let url = sender as? NSURL {
                // Provide the url to the view controller
                documentVC.documentURL = url
            } else {
                // it's something else, oh no!
                fatalError("ShowDocument segue was called with an " +
                    "invalid sender of type \(sender.dynamicType)")
            }
            
            
        }
    }
    // END prepare_for_segue_list
    
}


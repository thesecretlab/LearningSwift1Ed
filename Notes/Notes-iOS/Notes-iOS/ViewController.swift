//
//  MasterViewController.swift
//  Notes-iOS
//
//  Created by Jonathon Manning on 25/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import UIKit

class FileCollectionViewCell : UICollectionViewCell {
    @IBOutlet weak var fileNameLabel : UILabel?
}

class ViewController: UICollectionViewController {
    
    var queryDidFinishGatheringObserver : AnyObject?
    var queryDidUpdateObserver: AnyObject?
    
    var metadataQuery : NSMetadataQuery = {
        let metadataQuery = NSMetadataQuery()
        metadataQuery.searchScopes =
            [NSMetadataQueryUbiquitousDocumentsScope]
        metadataQuery.predicate = NSPredicate(format: "%K LIKE '*'",
            NSMetadataItemFSNameKey)
        
        return metadataQuery
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "createDocument")
        self.navigationItem.rightBarButtonItem = addButton
        
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
        
        metadataQuery.startQuery()
    }
    
    func queryUpdated() {
        self.collectionView?.reloadData()
        
        if let items = self.metadataQuery.results as? [NSMetadataItem] {
            for item in items {
                
                if itemIsOpenable(item) == true {
                    // We only need to download if it isn't already openable
                    continue
                }
                
                guard let url = item.valueForAttribute(NSMetadataItemURLKey) as? NSURL else {
                    // We need to URL to download it, so bail out
                    continue
                }
                
                do {
                    // Ask the system to try to download it
                    try NSFileManager.defaultManager().startDownloadingUbiquitousItemAtURL(url)
                } catch let error as NSError {
                    
                    // Log it if there was a problem
                    NSLog("Failed to start downloading item \(url): \(error)")
                }
            }

        }
    }
    
    // MARK: - Collection View
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // We only have one section
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // There are as many cells as there are items in iCloud
        return self.metadataQuery.resultCount
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // Get our cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FileCell", forIndexPath: indexPath) as! FileCollectionViewCell
        
        // We'll use this to store whether or not this is an accessible cell
        let openable : Bool
        
        // Attempt to get this object from the metadata query
        if let object = self.metadataQuery.resultAtIndex(indexPath.row) as? NSMetadataItem {
            // The display name is the visible name
            cell.fileNameLabel!.text = object.valueForAttribute(NSMetadataItemDisplayNameKey) as? String
            
            openable = itemIsOpenable(object)
            
        } else {
            cell.fileNameLabel!.text = "<error>"
            
            openable = false
            
        }
        
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
        
        return cell
        
    }
    
    func itemIsOpenable(item:NSMetadataItem?) -> Bool {
        
        guard let item = item else {
            return false
        }
    
        if let url = item.valueForAttribute(NSMetadataItemURLKey) as? NSURL {
            
            var downloadStatus : AnyObject?
            do {
                try url.getResourceValue(&downloadStatus, forKey: NSURLUbiquitousItemDownloadingStatusKey)
            } catch {
                return false
            }
            
            if downloadStatus as? String == NSURLUbiquitousItemDownloadingStatusCurrent {
                return true
            } else {
                return false
            }
            
        }
    
        return false
        
    }
    
    var localDocumentsDirectoryURL : NSURL = {
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    }()
    
    var ubiquitousDocumentsDirectoryURL : NSURL? {
        return NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(nil)?.URLByAppendingPathComponent("Documents")
    }
    
    func createDocument() {
        
        
        // Create a name for this
        let documentName = "Document \(rand()).note"
        
        // Work out where we're going to store it, temporarily
        let documentDestinationURL = localDocumentsDirectoryURL.URLByAppendingPathComponent(documentName)
        
        // Create the document and try to save it locally
        let newDocument = Document(fileURL:documentDestinationURL)
        newDocument.saveToURL(documentDestinationURL, forSaveOperation: .ForCreating) { (success) -> Void in
            
            // If we successfully created it, attempt to move it to iCloud
            if success == true, let ubiquitousDestinationURL = self.ubiquitousDocumentsDirectoryURL?.URLByAppendingPathComponent(documentName) {
                
                // Perform the move to iCloud in the background
                NSOperationQueue().addOperationWithBlock { () -> Void in
                    do {
                        try NSFileManager.defaultManager().setUbiquitous(true, itemAtURL: documentDestinationURL, destinationURL: ubiquitousDestinationURL)
                    } catch let error as NSError {
                        NSLog("Error storing document in iCloud! \(error)")
                    }
                }
            }
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // Did we select a cell that has an item that is openable?
        if let selectedItem = self.metadataQuery.resultAtIndex(indexPath.row) as? NSMetadataItem where itemIsOpenable(selectedItem) {
            
            self.performSegueWithIdentifier("ShowDocument", sender: selectedItem)
            
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // If segue is a NSMetadataItem, the segue is "ShowDocument" and the destination view controller is a DocumentViewController...
        if segue.identifier == "ShowDocument", let item = sender as? NSMetadataItem, let documentVC = segue.destinationViewController as? DocumentViewController
        {
            
            // .. get the URL and open it!
            if let url = item.valueForAttribute(NSMetadataItemURLKey) as? NSURL {
                documentVC.documentURL = url
            }
            
        }
    }
    
}


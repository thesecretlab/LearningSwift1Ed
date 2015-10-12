//
//  IndexRequestHandler.swift
//  Notes-SpotlightIndexer
//
//  Created by Jon Manning on 12/10/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

// BEGIN index_handler
import CoreSpotlight
import UIKit

class IndexRequestHandler: CSIndexExtensionRequestHandler {
    
    var availableFiles : [NSURL] {
        let fileManager = NSFileManager.defaultManager()
        
        guard let documentsFolder = fileManager.URLForUbiquityContainerIdentifier(nil)?
            .URLByAppendingPathComponent("Documents", isDirectory: true) else {
            
            NSLog("Spotlight Indexer extension cannot access Documents!")
            return []
        }
        
        do {
            
            // Get the list of files
            let allFiles = try fileManager
                .contentsOfDirectoryAtPath(documentsFolder.path!)
                .map({ documentsFolder.URLByAppendingPathComponent($0, isDirectory: false) })
            
            // Filter these to only those that end in ".note",
            // and return NSURLs of these
            return allFiles
                .filter({ $0.lastPathComponent?.hasSuffix(".note") ?? false})
            
            
        } catch  {
            // Log an error and return the empty array
            NSLog("Failed to get contents of Documents folder")
            return []
        }
    }
    
    func itemForURL(url: NSURL) -> CSSearchableItem? {
        
        // If this URL doesn't exist, return nil
        if url.checkResourceIsReachableAndReturnError(nil) == false {
            return nil
        }
        
        // Replace this with your own type identifier
        let attributeSet = CSSearchableItemAttributeSet(
            itemContentType: "au.com.secretlab.Note")
        
        attributeSet.title = url.lastPathComponent
        
        // Get the text in this file
        let textFileURL = url.URLByAppendingPathComponent(
            NoteDocumentFileNames.TextFile.rawValue)
        
        if let textData = NSData(contentsOfURL: textFileURL),
            let text = try? NSAttributedString(data: textData,
                options: [NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType],
                documentAttributes: nil) {
                    
                    attributeSet.contentDescription = text.string
                    
        } else {
            attributeSet.contentDescription = ""
        }
        
        let item = CSSearchableItem(uniqueIdentifier: url.absoluteString,
            domainIdentifier: "au.com.secretlab.Notes", attributeSet: attributeSet)
        
        return item
    }

    override func searchableIndex(searchableIndex: CSSearchableIndex,
        reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: () -> Void) {
        // Reindex all data with the provided index
        
        let files = availableFiles
        
        var allItems : [CSSearchableItem] = []
        
        for file in files {
            if let item = itemForURL(file) {
                allItems.append(item)
            }
            
        }
        
        searchableIndex.indexSearchableItems(allItems) { (error) -> Void in
            acknowledgementHandler()
        }
        
    }

    override func searchableIndex(searchableIndex: CSSearchableIndex, reindexSearchableItemsWithIdentifiers identifiers: [String], acknowledgementHandler: () -> Void) {
        // Reindex any items with the given identifiers and the provided index
        
        var itemsToIndex : [CSSearchableItem] = []
        var itemsToRemove : [String] = []
        
        for identifier in identifiers {
            
            if let url = NSURL(string: identifier),
                let item = itemForURL(url) {
                itemsToIndex.append(item)
            } else {
                itemsToRemove.append(identifier)
            }
        }
        
        searchableIndex.indexSearchableItems(itemsToIndex) { (error) -> Void in
            searchableIndex.deleteSearchableItemsWithIdentifiers(itemsToRemove) { (error) -> Void in
                acknowledgementHandler()
            }
        }
        
        
    }

}

// END index_handler

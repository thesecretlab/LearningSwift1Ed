//
//  TodayViewController.swift
//  Notes-TodayScreen
//
//  Created by Jonathon Manning on 3/09/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import UIKit
import NotificationCenter

// BEGIN ext_tableview_protocols
class TodayViewController: UIViewController, NCWidgetProviding, UITableViewDelegate, UITableViewDataSource
// END ext_tableview_protocols
{
    
    // BEGIN ext_file_list
    var fileList : [NSURL] = []
    // END ext_file_list
    
    // BEGIN ext_load_available_files
    func loadAvailableFiles() -> [NSURL] {
        
        let fileManager = NSFileManager.defaultManager()
        
        guard let documentsFolder = fileManager.URLForUbiquityContainerIdentifier(nil)?.URLByAppendingPathComponent("Documents", isDirectory: true) else {
            
            NSLog("Notes Today extension cannot access Documents!")
            return []
        }
        
        do {
            
            // Get the list of files
            let allFiles = try fileManager.contentsOfDirectoryAtPath(documentsFolder.path!).map({ documentsFolder.URLByAppendingPathComponent($0, isDirectory: false) })
            
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
    // END ext_load_available_files
    
    // BEGIN view_did_load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fileList = loadAvailableFiles()
        
        // We have nothing to show until we attempt to list the , so default to a very small size
        self.preferredContentSize = CGSize(width: 0, height: 1)
        
        let containerURL = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(nil)
        
        NSLog("Extension's container: \(containerURL)")
        
        // Do any additional setup after loading the view from its nib.
    }
    // END view_did_load
    
    @IBOutlet weak var tableView: UITableView!
    
    // BEGIN ext_update
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        let newFileList = loadAvailableFiles()
        
        self.preferredContentSize = self.tableView.contentSize
        
        if newFileList == fileList {
            completionHandler(.NoData)
        } else {
            fileList = newFileList
            
            completionHandler(.NewData)
        }
    }
    // END ext_update
    
    // BEGIN ext_tableview_datasource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return fileList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        let url = fileList[indexPath.row]
        cell.textLabel?.text = "\(url.lastPathComponent!)"
        
        return cell
    }
    // END ext_tableview_datasource
    
    // BEGIN ext_open_document
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let url = fileList[indexPath.row]
        
        guard let path = url.path else {
            return
        }
        
        let appURLComponents = NSURLComponents()
        appURLComponents.scheme = "notes"
        appURLComponents.host = nil
        appURLComponents.path = path
        
        if let appURL = appURLComponents.URL {
            self.extensionContext?.openURL(appURL, completionHandler: nil)
        }
    }
    // END ext_open_document
    
}

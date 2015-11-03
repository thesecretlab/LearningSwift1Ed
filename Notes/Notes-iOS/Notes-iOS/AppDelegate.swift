//
//  AppDelegate.swift
//  Notes-iOS
//
//  Created by Jonathon Manning on 25/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import UIKit

// BEGIN ios_watch_connectivity
import WatchConnectivity
// END ios_watch_connectivity

// BEGIN settings_notification_name
let NotesApplicationDidRegisterUserNotificationSettings = "NotesApplicationDidRegisterUserNotificationSettings"
// END settings_notification_name


// BEGIN ios_watch_wcsessiondelegate
extension AppDelegate : WCSessionDelegate {
    
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        
        if let messageName = message[WatchMessageTypeKey] as? String {
            
            switch messageName {
            case WatchMessageTypeListAllNotesKey:
                handleListAllNotes(replyHandler)
            case WatchMessageTypeLoadNoteKey:
                if let urlString = message[WatchMessageContentURLKey] as? String,
                    let url = NSURL(string: urlString) {
                    handleLoadNote(url, replyHandler: replyHandler)
                } else {
                    // if there's no URL, then fall through to the error case
                    fallthrough
                }
            case WatchMessageTypeCreateNoteKey:
                if let textForNote = message[WatchMessageContentTextKey] as? String {
                    handleCreateNote(textForNote, replyHandler: replyHandler)
                } else {
                    fallthrough
                }
                
                
            default:
                // No idea what this message is, so reply with the empty dictionary
                replyHandler([:])
            }
        }
    }
    
    func handleCreateNote(text: String, replyHandler: ([String:AnyObject]) -> Void) {
        
        let documentName = "Document \(arc4random()) from Watch.note"
        
        guard let documentsFolder = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory,
            inDomains: .UserDomainMask).first else {
                self.handleListAllNotes(replyHandler)
                return
        }
        
        guard let ubiquitousDocumentsDirectoryURL = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(nil)?
            .URLByAppendingPathComponent("Documents") else {
                self.handleListAllNotes(replyHandler)
                return
        }
        
        let documentDestinationURL = documentsFolder
            .URLByAppendingPathComponent(documentName)
        
        // Create the document and try to save it locally
        let newDocument = Document(fileURL:documentDestinationURL)
        
        newDocument.text = NSAttributedString(string: text)
        
        newDocument.saveToURL(documentDestinationURL,
            forSaveOperation: .ForCreating) { (success) -> Void in
                
                if success == false {
                    self.handleListAllNotes(replyHandler)
                    return
                }
                
                // Move it to iCloud
                let ubiquitousDestinationURL = ubiquitousDocumentsDirectoryURL
                    .URLByAppendingPathComponent(documentName)
                
                // Perform the move to iCloud in the background
                NSOperationQueue().addOperationWithBlock { () -> Void in
                    do {
                        try NSFileManager.defaultManager()
                            .setUbiquitous(true, itemAtURL: documentDestinationURL,
                                destinationURL: ubiquitousDestinationURL)
                        
                        
                    } catch let error as NSError {
                        NSLog("Error storing document in iCloud! \(error.localizedDescription)")
                    }
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                        // Pass back the list of everything currently in iCloud
                        self.handleListAllNotes(replyHandler)
                    }
                }
                
        }
    }

    func handleListAllNotes(replyHandler: ([String:AnyObject]) -> Void) {
        
        let fileManager = NSFileManager.defaultManager()
        
        guard let documentsFolder = fileManager.URLForUbiquityContainerIdentifier(nil)?.URLByAppendingPathComponent("Documents", isDirectory: true) else {
            
            NSLog("Cannot access Documents!")
            replyHandler([:])
            return
        }
        
        do {
            
            // Get the list of files
            let allFiles = try fileManager.contentsOfDirectoryAtPath(documentsFolder.path!).map({ documentsFolder.URLByAppendingPathComponent($0, isDirectory: false) })
            
            // Filter these to only those that end in ".note",
            // and return NSURLs of these
            
            let noteFiles = allFiles
                .filter({ $0.lastPathComponent?.hasSuffix(".note") ?? false})
            
            let results = noteFiles.map({ url in
                
                return [ // dict
                    WatchMessageContentNameKey: url.lastPathComponent!,
                    WatchMessageContentURLKey: url.absoluteString
                ]
                
            })
            
            let reply = [
                WatchMessageContentListKey: results
            ]
            
            replyHandler(reply)
            
        } catch  {
            // Log an error and return the empty array
            NSLog("Failed to get contents of Documents folder")
            replyHandler([:])
        }
        
    }
    
    func handleLoadNote(url: NSURL, replyHandler: ([String:AnyObject]) -> Void) {
        let document = Document(fileURL:url)
        document.openWithCompletionHandler { success in
            
            if success == false {
                replyHandler([:])
            }
            
            let reply = [
                WatchMessageContentTextKey: document.text.string
            ]
            
            // Close; don't provide a completion handler, because
            // we've not making changes and therefore don't care
            // if a save succeeds or not
            document.closeWithCompletionHandler(nil)
            
            replyHandler(reply)
        }
        
    }
}
// END ios_watch_wcsessiondelegate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // BEGIN access_to_icloud
        // Ensure we've got access to iCloud
        let backgroundQueue = NSOperationQueue()
        backgroundQueue.addOperationWithBlock() {
            // Pass 'nil' to this method to get the URL for the first
            // iCloud container listed in the app's entitlements
            let ubiquityContainerURL = NSFileManager.defaultManager()
                .URLForUbiquityContainerIdentifier(nil)
            print("Ubiquity container URL: \(ubiquityContainerURL)")
        }
        // END access_to_icloud
        
        // BEGIN ios_watch_did_finish_launching
        WCSession.defaultSession().delegate = self
        WCSession.defaultSession().activateSession()
        // END ios_watch_did_finish_launching
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // BEGIN open_url
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        if url.scheme == "notes", let path = url.path {
            
            // Return to the list of documents
            if let navigationController = self.window?.rootViewController as? UINavigationController {
                
                navigationController.popToRootViewControllerAnimated(false)
                
                 (navigationController.topViewController as? DocumentListViewController)?.openDocumentWithPath(path)
            }
            
            return true
            
        }
        
        return false
    }
    // END open_url
    
    // BEGIN local_notification_received
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        
        // Extract the document and open it
        if notification.category == Document.alertCategory,
            let url = notification.userInfo?["owner"] as? String,
            let navigationController = self.window?.rootViewController as? UINavigationController
            {
            if let path = NSURL(string: url)?.path {
                navigationController.popToRootViewControllerAnimated(false)
                
                (navigationController.topViewController as? DocumentListViewController)?.openDocumentWithPath(path)
            }
        }
        
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        
        if identifier == Document.alertSnoozeAction {
            // Reschedule the notification
            notification.fireDate = NSDate(timeIntervalSinceNow: 5)
            application.scheduleLocalNotification(notification)
        }
        
        completionHandler();
    }
    // END local_notification_received

    
    
    
    // BEGIN application_continue_activity
    func application(application: UIApplication,
        continueUserActivity userActivity: NSUserActivity,
        restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        
        // Return to the list of documents
        if let navigationController = self.window?.rootViewController as? UINavigationController {
            navigationController.popToRootViewControllerAnimated(false)
            
            // We're now at the list of documents; tell the restoration 
            // system that this view controller needs to be informed
            // that we're continuing the activity
            if let topViewController = navigationController.topViewController {
                restorationHandler([topViewController])
            }
            
            return true
        }
        return false
    }
    // END application_continue_activity
    
    // BEGIN application_did_register
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(NotesApplicationDidRegisterUserNotificationSettings, object: self)
    }
    // END application_did_register
    
    
    
    
}


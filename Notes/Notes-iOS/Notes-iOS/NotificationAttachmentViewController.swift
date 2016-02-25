//
//  NotificationAttachmentViewController.swift
//  Notes
//
//  Created by Jon Manning on 30/09/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import UIKit

// BEGIN notification_vc_attachment_protocol
class NotificationAttachmentViewController: UIViewController, AttachmentViewer {
    
    var document : Document?
    var attachmentFile : NSFileWrapper?
// END notification_vc_attachment_protocol
    
    @IBOutlet var datePicker : UIDatePicker!

    // BEGIN notification_vc_impl
    
    // BEGIN notification_observer
    var notificationSettingsWereRegisteredObserver : AnyObject?
    // END notification_observer
    
    
    /// BEGIN notification_view_will_appear
    override func viewWillAppear(animated:Bool) {
        
        if let notification = self.document?.localNotification {
            let cancelButton = UIBarButtonItem(barButtonSystemItem: .Trash,
                target: self, action: "clearNotificationAndClose")
            
            self.navigationItem.leftBarButtonItem = cancelButton
            
            self.datePicker.date = notification.fireDate ?? NSDate()
            
        } else {
            let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel,
                target: self, action: "clearNotificationAndClose")
            self.navigationItem.leftBarButtonItem = cancelButton
            
            self.datePicker.date = NSDate()
        }
        
        // Now add the Done button that adds the attachment
        let doneButton = UIBarButtonItem(barButtonSystemItem: .Done,
            target: self, action: "setNotificationAndClose")
        self.navigationItem.rightBarButtonItem = doneButton

        // Register for changes to user notification settings
        notificationSettingsWereRegisteredObserver = NSNotificationCenter
            .defaultCenter().addObserverForName(
                NotesApplicationDidRegisterUserNotificationSettings,
                object: nil, queue: nil,
                usingBlock: { (notification) -> Void in
                    
                    if let settings = UIApplication.sharedApplication()
                        .currentUserNotificationSettings() where
                        settings.types.contains(.Alert) == true {
                            self.datePicker.enabled = true
                            self.datePicker.userInteractionEnabled = true
                            doneButton.enabled = true
                    }
            })
        
        // If the app doesn't already have access, register for access
        if let settings = UIApplication.sharedApplication()
            .currentUserNotificationSettings()
            where settings.types.contains(.Alert) != true {
                
                let action = UIMutableUserNotificationAction()
                action.identifier = Document.alertSnoozeAction
                action.activationMode = .Background
                action.title = "Snooze"
                
                let category = UIMutableUserNotificationCategory()
                category.identifier = Document.alertCategory
            
                category.setActions(
                    [action],
                    forContext: UIUserNotificationActionContext.Default)
            
                category.setActions(
                    [action],
                    forContext: UIUserNotificationActionContext.Minimal)
                
                let settings = UIUserNotificationSettings(forTypes: .Alert,
                                                          categories: [category])
                
                UIApplication.sharedApplication()
                    .registerUserNotificationSettings(settings)
                
                self.datePicker.enabled = false
                self.datePicker.userInteractionEnabled = false
                doneButton.enabled = false
        }
    }
    // END notification_view_will_appear
    
    // BEGIN notification_save_and_close
    func setNotificationAndClose() {
        
        // Prepare and add the notification if the date picker
        // isn't set in the future
        let date : NSDate
        
        if self.datePicker.date.timeIntervalSinceNow < 5 {
            date = NSDate(timeIntervalSinceNow: 5)
        } else {
            date = self.datePicker.date
        }
        
        let notification = UILocalNotification()
        notification.fireDate = date
        
        notification.alertTitle = "Notes Alert"
        notification.alertBody = "Check out your document!"
        
        notification.category = Document.alertCategory
        
        self.document?.localNotification = notification
    
        self.presentingViewController?.dismissViewControllerAnimated(true,
            completion: nil)
    }
    // END notification_save_and_close
    
    // BEGIN notification_clear_and_close
    func clearNotificationAndClose() {
        self.document?.localNotification = nil
        self.presentingViewController?.dismissViewControllerAnimated(true,
            completion: nil)
    }
    // END notification_clear_and_close
    // END notification_vc_impl

}

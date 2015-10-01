//
//  NotificationAttachmentViewController.swift
//  Notes
//
//  Created by Jon Manning on 30/09/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import UIKit

class NotificationAttachmentViewController: UIViewController, AttachmentViewer {
    
    var document : Document?
    var attachmentFile : NSFileWrapper?
    
    @IBOutlet var datePicker : UIDatePicker!

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

        
        if let settings = UIApplication.sharedApplication().currentUserNotificationSettings() where
            settings.types.contains(.Alert) != true {
                
                let action = UIMutableUserNotificationAction()
                action.identifier = Document.alertSnoozeAction;
                action.activationMode = .Background
                action.title = "Snooze"
                
                let category = UIMutableUserNotificationCategory()
                category.identifier = Document.alertCategory
                category.setActions([action], forContext: UIUserNotificationActionContext.Default)
                category.setActions([action], forContext: UIUserNotificationActionContext.Minimal)
                
                let settings = UIUserNotificationSettings(forTypes: .Alert, categories: [category])
                
                UIApplication.sharedApplication().registerUserNotificationSettings(settings)
                
                self.datePicker.enabled = false
                self.datePicker.userInteractionEnabled = false
                doneButton.enabled = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setNotificationAndClose() {
        
        // Prepare and add the notification if the date picker is not set in the future
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
    
    func clearNotificationAndClose() {
        self.document?.localNotification = nil
        self.presentingViewController?.dismissViewControllerAnimated(true,
            completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

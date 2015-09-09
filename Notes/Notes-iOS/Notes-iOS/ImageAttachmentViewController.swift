//
//  ImageAttachmentViewController.swift
//  Notes
//
//  Created by Jonathon Manning on 27/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import UIKit

// BEGIN image_view_controller_definition
class ImageAttachmentViewController: UIViewController, AttachmentViewer {
// END image_view_controller_definition
    
    // BEGIN image_vc_outlet
    @IBOutlet weak var imageView : UIImageView?
    // END image_vc_outlet
    
    // BEGIN image_vc_attachmentviewer
    var attachmentFile : NSFileWrapper?
    
    var document : Document?
    // END image_vc_attachmentviewer

    // BEGIN view_did_load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If we have data, and can make an image out of it...
        if let data = attachmentFile?.regularFileContents, let image = UIImage(data: data) {
            // Set the image
            self.imageView?.image = image
        }
    }
    // END view_did_load

    @IBAction func shareImage(sender: UIBarButtonItem) {
        
        // Ensure that we're actually showing an image
        guard let image = self.imageView?.image else {
            return
        }
        
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        // If we are being presented in a window that's a Regular width, show it in a popover (rather than the default modal)
        if UIApplication.sharedApplication().keyWindow?.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.Regular {
            activityController.modalPresentationStyle = .Popover
            
            activityController.popoverPresentationController?.barButtonItem = sender
        }
        
        self.presentViewController(activityController, animated: true, completion: nil)
        
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

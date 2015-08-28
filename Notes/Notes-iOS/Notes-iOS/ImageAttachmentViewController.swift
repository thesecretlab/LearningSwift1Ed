//
//  ImageAttachmentViewController.swift
//  Notes
//
//  Created by Jonathon Manning on 27/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import UIKit

class ImageAttachmentViewController: UIViewController, AttachmentViewer {
    
    @IBOutlet weak var imageView : UIImageView?
    
    var attachmentFile : NSFileWrapper?
    var document : Document?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If we have data, and can make an image out of it...
        if let data = attachmentFile?.regularFileContents, let image = UIImage(data: data) {
            // Set the image
            self.imageView?.image = image
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func shareImage(sender: UIBarButtonItem) {
        
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

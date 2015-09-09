//
//  AddAttachmentViewController.swift
//  Notes
//
//  Created by Jonathon Manning on 27/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import UIKit

// BEGIN add_attachment_delegate
protocol AddAttachmentDelegate {
    func addPhoto()
    // BEGIN add_attachment_delegate_location
    func addLocation()
    // END add_attachment_delegate_location
}
// END add_attachment_delegate

class AddAttachmentViewController: UIViewController {
    
    // BEGIN add_attachment_delegate_property
    var delegate : AddAttachmentDelegate?
    // END add_attachment_delegate_property
    
    // BEGIN add_attachment_addphoto
    @IBAction func addPhoto(sender: AnyObject) {
        self.presentingViewController?
            .dismissViewControllerAnimated(true, completion: {
                self.delegate?.addPhoto()
            })
    }
    // END add_attachment_addphoto
    
    // BEGIN add_attachment_addlocation
    @IBAction func addLocation(sender: AnyObject) {
        self.presentingViewController?
            .dismissViewControllerAnimated(true, completion: {
                self.delegate?.addLocation()
            })
    }
    // END add_attachment_addlocation

}

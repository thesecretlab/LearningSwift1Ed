//
//  AddAttachmentViewController.swift
//  Notes
//
//  Created by Jonathon Manning on 25/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import Cocoa

// BEGIN add_attachment_protocol
protocol AddAttachmentDelegate {
    
    func addFile()
    
}
// END add_attachment_protocol

class AddAttachmentViewController: NSViewController {
    
    // BEGIN add_attachment_delegate_property
    var delegate : AddAttachmentDelegate?
    // END add_attachment_delegate_property

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    // BEGIN add_attachment_add_file
    @IBAction func addFile(sender: AnyObject) {
        self.delegate?.addFile()
    }
    // END add_attachment_add_file
    
    
}

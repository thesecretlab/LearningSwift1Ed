//
//  AddAttachmentViewController.swift
//  Notes
//
//  Created by Jonathon Manning on 25/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import Cocoa

protocol AddAttachmentDelegate {
    
    func addFile()
    
}

class AddAttachmentViewController: NSViewController {
    
    var delegate : AddAttachmentDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func addFile(sender: AnyObject) {
        self.delegate?.addFile()
    }
}

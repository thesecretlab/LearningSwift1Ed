//
//  AttachmentCellViewController.swift
//  Notes
//
//  Created by Jon Manning on 12/01/2016.
//  Copyright © 2016 Jonathon Manning. All rights reserved.
//

import Cocoa

// BEGIN attachment_cell_mac
class AttachmentCell: NSCollectionViewItem {
    
    // BEGIN attachment_cell_mac_delegate
    weak var delegate : AttachmentCellDelegate?
    // END attachment_cell_mac_delegate
    
    // BEGIN attachment_cell_mousedown
    override func mouseDown(theEvent: NSEvent) {
        if (theEvent.clickCount == 2) {
            delegate?.openSelectedAttachment(self)
        }
    }
    // END attachment_cell_mousedown
}
// END attachment_cell_mac

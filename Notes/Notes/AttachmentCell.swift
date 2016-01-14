//
//  AttachmentCellViewController.swift
//  Notes
//
//  Created by Jon Manning on 12/01/2016.
//  Copyright © 2016 Jonathon Manning. All rights reserved.
//

import Cocoa

// BEGIN attachment_cell
class AttachmentCell: NSCollectionViewItem {
    
    weak var delegate : AttachmentCellDelegate?
    
    // BEGIN attachment_cell_mousedown
    override func mouseDown(theEvent: NSEvent) {
        if (theEvent.clickCount == 2) {
            delegate?.openSelectedAttachment(self)
        }
    }
    // END attachment_cell_mousedown
}
// END attachment_cell

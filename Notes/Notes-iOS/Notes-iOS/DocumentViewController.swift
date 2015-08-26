//
//  DocumentViewController.swift
//  Notes
//
//  Created by Jonathon Manning on 26/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import UIKit

class DocumentViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var textView : UITextView?
    
    private var document : Document?
    
    func textViewDidChange(textView: UITextView) {
        document?.text = textView.attributedText
        document?.updateChangeCount(.Done)
    }
    
    // The location of the document we're showing
    var documentURL:NSURL? {
        // When it's set, create a new document object for us to open
        didSet {
            if let url = documentURL {
                self.document = Document(fileURL:url)
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        // Ensure that we actually have a document
        guard let document = self.document else {
            NSLog("No document to display!")
            self.navigationController?.popViewControllerAnimated(true)
            return
        }
        
        // If this document is not already open, open it
        if document.documentState.contains(UIDocumentState.Closed) {
            document.openWithCompletionHandler { (success) -> Void in
                if success == true {
                    self.textView?.attributedText = document.text
                } else {
                    
                    // We can't open it! Show an alert!
                    let alertTitle = "Error"
                    let alertMessage = "Failed to open document"
                    let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
                    
                    // Add a button that returns to the previous screen
                    alert.addAction(UIAlertAction(title: "Close", style: .Default, handler: { (action) -> Void in
                        self.navigationController?.popViewControllerAnimated(true)
                    }))
                    
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.document?.closeWithCompletionHandler(nil)
    }

}

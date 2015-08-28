//
//  AddAttachmentViewController.swift
//  Notes
//
//  Created by Jonathon Manning on 27/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import UIKit

protocol AddAttachmentDelegate {
    func addPhoto()
    func addLocation()
}

class AddAttachmentViewController: UIViewController {
    
    var delegate : AddAttachmentDelegate?
    
    @IBAction func addPhoto(sender: UIButton) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: { delegate?.addPhoto() })
    }
    
    @IBAction func addLocation(sender: UIButton) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: { delegate?.addLocation() })
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}

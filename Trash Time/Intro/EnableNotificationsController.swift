//
//  EnableNotificationsController.swift
//  Trash Time
//
//  Created by Thomas Hajcak on 4/10/15.
//  Copyright (c) 2015 Simple Ink. All rights reserved.
//

import UIKit
import TrashTimeShare

class EnableNotificationsController : UIViewController {
    
    @IBOutlet weak var finishButton: UIBarButtonItem!
    
    override func viewWillAppear(animated: Bool) {

    }
    
    @IBAction func finishSetup(sender: UIBarButtonItem) {
        
        func finalizeSetup() {
            Logic.instance.setWelcomeComplete()
            Logic.instance.setupNotifications()
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        finalizeSetup()
    }
    
    @IBAction func askForNotifications(sender: AnyObject) {
        Logic.instance.requestNotificationPermission()
    }
}

//
//  WelcomeController.swift
//  Trash Time
//
//  Created by Thomas Hajcak on 4/9/15.
//  Copyright (c) 2015 Simple Ink. All rights reserved.
//

import UIKit

class WelcomeController : UIViewController {
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewDidAppear(animated: Bool) {
        let timer = NSTimer.scheduledTimerWithTimeInterval(2,
            target: self,
            selector: "showNextView",
            userInfo: nil,
            repeats: false)
    }
    
    func showNextView() {
        if (self.navigationController?.visibleViewController == self) {
            self.showNextPage(self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let controller = segue.destinationViewController as! SetupController
        controller.currentSetup = .Trash
    }
    
    @IBAction func showNextPage(sender: AnyObject) {
        self.performSegueWithIdentifier("showTrashView", sender: self)
    }
}

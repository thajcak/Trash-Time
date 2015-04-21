//
//  TimingSetupController.swift
//  Trash Time
//
//  Created by Thomas Hajcak on 4/9/15.
//  Copyright (c) 2015 Simple Ink. All rights reserved.
//

import UIKit
import TrashTimeShare

class TimingSetupController : UIViewController, UIPickerViewDelegate {
    
    @IBOutlet weak var notificationTimePicker: UIDatePicker!
    @IBOutlet weak var notificationTimingSegmentedControl: UISegmentedControl!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    override func viewWillAppear(animated: Bool) {
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
        
        if (UIApplication.sharedApplication().currentUserNotificationSettings().types == UIUserNotificationType.allZeros) {
            self.nextButton.title = "Continue"
        } else {
            self.nextButton.title = "Finish"
        }
        
        self.navigationController?.navigationBar.tintColor = self.view.tintColor
    }
    
    override func viewDidAppear(animated: Bool) {
        Logic.instance.setNotificationTime(self.notificationTimePicker.date)
    }
    
    @IBAction func notificationTimeChanged(sender: UIDatePicker) {
        Logic.instance.setNotificationTime(sender.date)
    }
    
    @IBAction func notificationTimingChanged(sender: UISegmentedControl) {
        Logic.instance.setAlertDay(Logic.AlertDay(rawValue: sender.selectedSegmentIndex)!)
    }
    
    @IBAction func nextAction(sender: AnyObject) {
        if (UIApplication.sharedApplication().currentUserNotificationSettings().types == UIUserNotificationType.None) {
            self.performSegueWithIdentifier("Request Notifications", sender: self)
        } else {
            Logic.instance.setWelcomeComplete()
            Notifications.instance.setupNotifications()
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}

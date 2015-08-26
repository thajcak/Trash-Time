//
//  SetupController.swift
//  Trash Time
//
//  Created by Thomas Hajcak on 4/9/15.
//  Copyright (c) 2015 Simple Ink. All rights reserved.
//

import UIKit
import TrashTimeShare

class SetupController: UIViewController, UIPickerViewDelegate, RSDFDatePickerViewDelegate {
    
    @IBOutlet weak var calendarVerticalSpaceConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var mainIconImage: UIImageView!
    @IBOutlet weak var toggleSwitch: RAMPaperSwitch!
    @IBOutlet weak var questionLabel: UILabel!
    
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var backButton: UIBarButtonItem!
    
    @IBOutlet weak var recyclingParitySegmentedControl: UISegmentedControl!
    @IBOutlet weak var calendarView: RSDFDatePickerView!
    
    @IBOutlet weak var notificationTimePicker: UIDatePicker!
    @IBOutlet weak var notificationTimingSegmentedControl: UISegmentedControl!
    @IBOutlet weak var timePickerVerticalSpaceConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var notificationsButton: UIButton!
    
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var welcomeLabel: TOMSMorphingLabel!
    
    var textIndex = -1
    var setupIndex = 0
    var currentSetup: SetupType = .Trash
    let logic = Logic.instance
    
    enum SetupType: Int {
        case Trash
        case Recycling
        case Time
        case Notifications
    }
    
    func colorForSetupType() -> UIColor {
        switch self.currentSetup {
        case .Recycling:
            return Theme.Color.Green.color()
        default:
            return Theme.Color.Blue.color()
        }
    }
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        self.toggleSwitch.animationDidStartClosure = {(onAnimation: Bool) in
            self.animateSwitchChange(onAnimation, animating: true)
        }
        
        self.calendarView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        self.logic.forgetEverything()
        self.setSetupType()
        
        self.navigationController?.navigationBar.tintColor = colorForSetupType()
    }
    
    override func viewDidAppear(animated: Bool) {
        logic.setNotificationTime(NSDate())
        
        self.prepareView()
        self.setupMessage(false)
    }
    
    // MARK: - Animations
    
    func animateSwitchChange(onAnimation: Bool, animating: Bool) {
//        let destination = (onAnimation ? self.view.frame.height/3 : 0)
        
        if (onAnimation) {
            self.calendarView.scrollToDate(NSDate(), animated: false)
            if (onAnimation) {
                switch self.currentSetup {
                case .Trash:
                    self.nextButton.enabled = self.logic.hasTrashReferenceDate()
                case .Recycling:
                    self.nextButton.enabled = self.logic.hasRecyclingReferenceDate()
                default: break
                }
            }
        } else {
            self.view.backgroundColor = Theme.Color.White.color()
            self.nextButton.enabled = true
        }
        
        UIView.animateWithDuration((animating ? self.toggleSwitch.duration : 0.01),
            delay: 0,
            options: .TransitionCrossDissolve,
            animations: {
                self.mainIconImage.highlighted = onAnimation
                self.navigationController?.navigationBar.tintColor = (onAnimation ? Theme.Color.White.color() : self.colorForSetupType())
                if (self.overlayView.alpha == 0) {
                    UIApplication.sharedApplication().setStatusBarStyle((onAnimation ? UIStatusBarStyle.LightContent : UIStatusBarStyle.Default), animated: true)
                }
            },
            completion: {(finished: Bool) in
                UIView.animateWithDuration((animating ? 0.6 : 0.01),
                    delay: 0,
                    usingSpringWithDamping: 0.7,
                    initialSpringVelocity: 0.3,
                    options: .CurveEaseInOut,
                    animations: {
                        self.nextButton.title = (onAnimation ? "Continue" : "Skip")
                        self.navigationController?.navigationBar.tintColor = (onAnimation ? Theme.Color.White.color() : self.colorForSetupType())
                        self.calendarVerticalSpaceConstraint.constant = (onAnimation ? -self.calendarView.frame.height : 0)
                        self.questionLabel.alpha = (onAnimation ? 1 : 0)
                        self.recyclingParitySegmentedControl.alpha = (onAnimation ? 1 : 0)
                        self.view.layoutIfNeeded()
                    },
                    completion: {(finished: Bool) in
                        self.view.backgroundColor = (onAnimation ? self.colorForSetupType() : Theme.Color.White.color())
                        self.toggleSwitch.layoutSubviews()
                    }
                )
            }
        )
    }
    
    func hideIntroMessage() {
        switch self.currentSetup {
        case .Trash: fallthrough
        case .Recycling: UIApplication.sharedApplication().setStatusBarStyle((self.toggleSwitch.on ? UIStatusBarStyle.LightContent : UIStatusBarStyle.Default), animated: true)
        default: UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
        }
        
        UIView.animateWithDuration(0.5, animations: {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.welcomeLabel.alpha = 0
            self.overlayView.alpha = 0
        })
    }
    
    func showIntroMessage() {
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
        UIView.animateWithDuration(0.5,
            animations: {
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.welcomeLabel.alpha = 1
                self.overlayView.alpha = 1
                self.notificationTimingSegmentedControl.alpha = 0
                self.timePickerVerticalSpaceConstraint.constant = 0
            },
            completion: {
                (finished: Bool) in
                self.setSetupType()
                self.prepareView()
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                    self.navigationController?.setNavigationBarHidden(false, animated: true)
                    switch self.currentSetup {
                    case .Trash: fallthrough
                    case .Recycling: self.hideIntroMessage()
                    case .Time: self.showTimePicker()
                    case .Notifications: self.showNotificationsButton()
                    }
                })
                
            }
        )
    }
    
    func showTimePicker() {
        UIView.animateWithDuration(0.6,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.3,
            options: .CurveEaseInOut,
            animations: {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.notificationTimingSegmentedControl.alpha = 1
                self.timePickerVerticalSpaceConstraint.constant = -self.notificationTimePicker.frame.height
                self.view.layoutIfNeeded()
            },
            completion: nil
        )
    }
    
    func showNotificationsButton() {
        
        UIView.animateWithDuration(0.5, animations: {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.notificationsButton.alpha = 1
        })
    }
    
    // MARK: - Control
    
    func setupTypes() -> [SetupType] {
        return [
            .Trash,
            .Recycling,
            .Time,
            .Notifications
        ]
    }
    
    func setSetupType() {
        switch currentSetup {
        case .Trash:
            self.mainIconImage.image = Theme.fillImage(UIImage(named: "Trash")!, color: Theme.Color.Blue)
            self.mainIconImage.highlightedImage = Theme.fillImage(UIImage(named: "Trash")!, color: Theme.Color.White)
            self.questionLabel.text = "When is your next trash collection?"
            self.recyclingParitySegmentedControl.hidden = true
        case .Recycling:
            self.mainIconImage.image = Theme.fillImage(UIImage(named: "Recycle")!, color: Theme.Color.Green)
            self.mainIconImage.highlightedImage = Theme.fillImage(UIImage(named: "Recycle")!, color: Theme.Color.White)
            self.questionLabel.text = "When is your next recycling collection?"
            self.recyclingParitySegmentedControl.hidden = false
            self.recyclingParitySegmentedControl.alpha = 0
            self.logic.setAlertDay(Logic.AlertDay(rawValue: self.recyclingParitySegmentedControl.selectedSegmentIndex)!)
        default: break
        }
        
        self.navigationController?.navigationBar.tintColor = self.colorForSetupType()
        self.toggleSwitch.onTintColor = colorForSetupType()
        self.toggleSwitch.awakeFromNib()
    }
    
    func prepareView() {
        switch self.currentSetup {
        case .Trash:
            self.backButton.title = ""
            self.calendarView.selectDate(self.logic.hasTrashReferenceDate() ? self.logic.trashNextCollection() : nil)
            self.toggleSwitch.setOn(self.logic.hasTrashReferenceDate(), animated: true)
            self.navigationController?.navigationBar.tintColor = (self.toggleSwitch.on ? Theme.Color.White.color() : self.colorForSetupType())
            self.nextButton.title = (self.toggleSwitch.on ? "Continue" : "Skip")
        case .Recycling:
            self.backButton.title = "Back"
            self.calendarView.selectDate(self.logic.hasRecyclingReferenceDate() ? self.logic.recyclingNextCollection() : nil)
            self.toggleSwitch.setOn(self.logic.hasRecyclingReferenceDate(), animated: true)
            self.navigationController?.navigationBar.tintColor = (self.toggleSwitch.on ? Theme.Color.White.color() : self.colorForSetupType())
            self.nextButton.title = (self.toggleSwitch.on ? "Continue" : "Skip")
        case .Time:
            self.backButton.title = "Back"
            if (UIApplication.sharedApplication().currentUserNotificationSettings()!.types == UIUserNotificationType()) {
                self.nextButton.title = "Continue"
            } else {
                self.nextButton.title = "Finish"
            }
        case .Notifications:
            self.nextButton.title = "Finish"
        }
    }
    
    func setupMessage(goingBack: Bool) {
        self.welcomeLabel.textColor = self.colorForSetupType()
        
        if (goingBack) {
            self.welcomeLabel.text = "going back"
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.25 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                self.welcomeLabel.text = ""
                self.hideIntroMessage()
            })
        } else {
            switch self.currentSetup {
            case .Trash:
                self.welcomeLabel.text = "hello"
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.25 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                    self.welcomeLabel.text = "let's get started"
                })
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2.5 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                    self.welcomeLabel.text = "first, trash alerts"
                })
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(4.25 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                    self.welcomeLabel.text = ""
                    self.hideIntroMessage()
                })
            case .Recycling:
                self.welcomeLabel.text = "next, recycling"
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.25 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                    self.welcomeLabel.text = ""
                    self.hideIntroMessage()
                })
            case .Time:
                self.welcomeLabel.text = "when should I remind you?"
            case .Notifications:
                self.welcomeLabel.text = "may I send you alerts?"
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func switchChanged(sender: UISwitch) {
        switch self.currentSetup {
        case .Trash:
            logic.toggleSection(Logic.SectionType.Trash, toggle: sender.on)
        case .Recycling:
            logic.toggleSection(Logic.SectionType.Recycling, toggle: sender.on)
        default: break
        }
    }
    
    @IBAction func alertDayChanged(sender: UISegmentedControl) {
        self.logic.setRecyclingFrequencyParity(sender.selectedSegmentIndex)
    }
    
    @IBAction func notificationTimeChanged(sender: UIDatePicker) {
        logic.setNotificationTime(sender.date)
    }
    
    @IBAction func notificationTimingChanged(sender: UISegmentedControl) {
        logic.setAlertDay(Logic.AlertDay(rawValue: sender.selectedSegmentIndex)!)
    }
    
    @IBAction func askForNotifications(sender: AnyObject) {
        Notifications.instance.requestNotificationPermission()
    }
    
    // MARK: - Calendar Delegate
    
    func datePickerView(view: RSDFDatePickerView!, didSelectDate date: NSDate!) {
        switch currentSetup {
        case .Trash:
            logic.setTrashReferenceDate(date)
        case .Recycling:
            logic.setRecyclingReferenceDate(date)
        default: break
        }
        self.nextButton.enabled = true
    }
    
    // MARK: - Navigation Control
    
    @IBAction func nextButtonTapped(sender: AnyObject) {
        if let nextStep = SetupType(rawValue: self.currentSetup.rawValue + 1) {
            self.currentSetup = nextStep
        }
        self.showIntroMessage()
        self.setupMessage(false)
        
        switch currentSetup {
        case .Notifications:
//            if (UIApplication.sharedApplication().currentUserNotificationSettings().types != UIUserNotificationType.None) {
                self.finishWelcome()
//            }
        default: break
        }
        
        
    }
    
    @IBAction func backButtonTapped(sender: AnyObject) {
        self.currentSetup = SetupType(rawValue: self.currentSetup.rawValue - 1)!
        self.showIntroMessage()
        self.setupMessage(true)
    }
    
    func finishWelcome() {
        logic.setWelcomeComplete()
        Notifications.instance.setupNotifications()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

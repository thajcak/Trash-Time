//
//  SetupController.swift
//  Trash Time
//
//  Created by Thomas Hajcak on 4/9/15.
//  Copyright (c) 2015 Simple Ink. All rights reserved.
//

import UIKit
import TrashTimeShare

class SetupController: UIViewController, RSDFDatePickerViewDelegate {
    
    @IBOutlet weak var calendarVerticalSpaceConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var mainIconImage: UIImageView!
    @IBOutlet weak var toggleSwitch: RAMPaperSwitch!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    @IBOutlet weak var recyclingParitySegmentedControl: UISegmentedControl!
    @IBOutlet weak var calendarView: RSDFDatePickerView!
    
    var currentSetup: SetupType?
    let logic = Logic.instance
    
    enum SetupType {
        case Trash
        case Recycling
    }
    
    func colorForSetupType() -> UIColor {
        switch self.currentSetup! {
        case .Trash:
            return Theme.ImageColor.Blue.color()
        case .Recycling:
            return Theme.ImageColor.Green.color()
        }
    }
    
    func closeUpdateView() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        
        if (currentSetup == nil) {
            currentSetup = .Trash
        }
        
        switch currentSetup! {
        case .Trash:
            self.mainIconImage.image = Theme.fillImage(UIImage(named: "Trash")!, color: Theme.ImageColor.Blue)
            self.mainIconImage.highlightedImage = Theme.fillImage(UIImage(named: "Trash")!, color: Theme.ImageColor.White)
            self.questionLabel.text = "When is your next trash collection?"
            self.recyclingParitySegmentedControl.hidden = true
        case .Recycling:
            self.mainIconImage.image = Theme.fillImage(UIImage(named: "Recycle")!, color: Theme.ImageColor.Green)
            self.mainIconImage.highlightedImage = Theme.fillImage(UIImage(named: "Recycle")!, color: Theme.ImageColor.White)
            self.questionLabel.text = "When is your next recycling collection?"
            self.recyclingParitySegmentedControl.hidden = false
            self.recyclingParitySegmentedControl.alpha = 0
            self.logic.setAlertDay(Logic.AlertDay(rawValue: self.recyclingParitySegmentedControl.selectedSegmentIndex)!)
        }
        
        self.toggleSwitch.onTintColor = colorForSetupType()
        self.toggleSwitch.awakeFromNib()
        
        self.toggleSwitch.animationDidStartClosure = {(onAnimation: Bool) in
            let destination = (onAnimation ? self.view.frame.height/3 : 0)
            
            if (self.toggleSwitch.on) {
                self.calendarView.scrollToDate(NSDate(), animated: false)
                switch self.currentSetup {
                case .Some(.Trash):
                    self.nextButton.enabled = self.logic.hasTrashReferenceDate()
                case .Some(.Recycling):
                    self.nextButton.enabled = self.logic.hasRecyclingReferenceDate()
                case .None: break
                }
            } else {
                self.view.backgroundColor = UIColor.whiteColor()
                self.nextButton.enabled = true
            }
            
            UIView.animateWithDuration(self.toggleSwitch.duration,
                delay: 0,
                options: .TransitionCrossDissolve,
                animations: {
                    self.mainIconImage.highlighted = onAnimation
                    UIApplication.sharedApplication().setStatusBarStyle((onAnimation ? UIStatusBarStyle.LightContent : UIStatusBarStyle.Default), animated: true)
                    self.navigationController?.navigationBar.tintColor = (self.toggleSwitch.on ? UIColor.whiteColor() : self.colorForSetupType())
                    self.nextButton.title = ""
                },
                completion: {(finished: Bool) in
                    UIView.animateWithDuration(0.6,
                        delay: 0,
                        usingSpringWithDamping: 0.7,
                        initialSpringVelocity: 0.3,
                        options: .CurveEaseInOut,
                        animations: {
                            self.nextButton.title = (onAnimation ? "Continue" : "Skip")
                            self.navigationController?.navigationBar.tintColor = (self.toggleSwitch.on ? UIColor.whiteColor() : self.colorForSetupType())
                            self.calendarVerticalSpaceConstraint.constant = (onAnimation ? -self.calendarView.frame.height : 0)
                            self.questionLabel.alpha = (onAnimation ? 1 : 0)
                            self.recyclingParitySegmentedControl.alpha = (onAnimation ? 1 : 0)
                            self.view.layoutIfNeeded()
                        },
                        completion: {(finished: Bool) in
                            self.view.backgroundColor = (self.toggleSwitch.on ? self.colorForSetupType() : UIColor.whiteColor())
                            self.toggleSwitch.layoutSubviews()
                        }
                    )
                }
            )
        }
        
        self.navigationController?.navigationBar.tintColor = (self.toggleSwitch.on ? UIColor.whiteColor() : colorForSetupType())
        
        self.calendarView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        
        if (currentSetup == .Trash) {
            self.navigationItem.setHidesBackButton(true, animated: false)
        }
        
        self.navigationController?.navigationBar.tintColor = (self.toggleSwitch.on ? UIColor.whiteColor() : colorForSetupType())
        
        UIApplication.sharedApplication().setStatusBarStyle((self.toggleSwitch.on ? UIStatusBarStyle.LightContent : UIStatusBarStyle.Default), animated: true)
    }
    
    @IBAction func switchChanged(sender: UISwitch) {
        switch self.currentSetup {
        case .Some(.Trash):
            logic.toggleSection(Logic.SectionType.Trash, toggle: sender.on)
        case .Some(.Recycling):
            logic.toggleSection(Logic.SectionType.Recycling, toggle: sender.on)
        case .None: break
        }
        
    }
    
    @IBAction func alertDayChanged(sender: UISegmentedControl) {
        self.logic.setRecyclingFrequencyParity(sender.selectedSegmentIndex)
    }
    
    // MARK: - Calendar Delegate
    
    func datePickerView(view: RSDFDatePickerView!, didSelectDate date: NSDate!) {
        switch currentSetup {
        case .Some(.Trash):
            logic.setTrashReferenceDate(date)
        case .Some(.Recycling):
            logic.setRecyclingReferenceDate(date)
        case .None: break
        }
        self.nextButton.enabled = true
    }
    
    // MARK: - Navigation Control
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showSetupController") {
            let controller = segue.destinationViewController as! SetupController
            controller.currentSetup = .Recycling
        }
    }
    
    @IBAction func nextButtonTapped(sender: AnyObject) {
        switch currentSetup! {
        case .Trash:
            self.performSegueWithIdentifier("showSetupController", sender: self)
        case .Recycling:
            self.performSegueWithIdentifier("showTiming", sender: self)
        }
    }
    
}

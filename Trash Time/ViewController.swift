//
//  ViewController.swift
//  Trash Time
//
//  Created by Thomas Hajcak on 4/8/15.
//  Copyright (c) 2015 Simple Ink. All rights reserved.
//

import UIKit
import TrashTimeShare

class ViewController: UIViewController, RSDFDatePickerViewDelegate, UIAlertViewDelegate {

    var currentSection: SectionType?
    
    let logic = Logic.instance
    
    let trashPopOver = AMPopTip()
    let recyclingPopOver = AMPopTip()
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        trashPopOver.popoverColor = Theme.Color.White.color()
        trashPopOver.textColor = Theme.Color.Black.color()
        recyclingPopOver.popoverColor = Theme.Color.White.color()
        recyclingPopOver.textColor = Theme.Color.Black.color()
        
        func addShadow(view: UIView) {
            view.layer.shadowColor = UIColor.blackColor().CGColor
            view.layer.shadowOffset = CGSizeMake(2, 0)
            view.layer.shadowOpacity = 0.8
            view.layer.shadowRadius = 1
        }
        
        addShadow(self.trashShadowView)
        addShadow(self.recyclingShadowView)
        
        logic.defaultDefaults()
        
        self.calendarView.delegate = self
        
        self.trashSwitch.onTintColor = Theme.Color.Blue.color()
        self.recycleSwitch.onTintColor = Theme.Color.Green.color()
        
        // Setup transition for icons when switch is flicked
        trashSwitch.animationDidStartClosure = {(onAnimation: Bool) in
            if (self.logic.hasTrashReferenceDate()) {
                self.logic.setSectionEnabled(Logic.SectionType.Trash, enabled: onAnimation)
            }
            self.setSectionVisibility(.Trash, enable: onAnimation)
        }
        recycleSwitch.animationDidStartClosure = {(onAnimation: Bool) in
            if (self.logic.hasRecyclingReferenceDate()) {
                self.logic.setSectionEnabled(Logic.SectionType.Recycling, enabled: onAnimation)
            }
            self.setSectionVisibility(.Recycling, enable: onAnimation)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateDisplay", name: "ENTERED_FOREGROUND", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        setupImages()
        
        let trashEnabled = logic.trashEnabled()
        self.trashSwitch.setOn(trashEnabled, animated: true)
        self.setSectionVisibility(.Trash, enable: trashEnabled, animate: false)
        
        let recyclingEnabled = logic.recyclingEnabled()
        self.recycleSwitch.setOn(recyclingEnabled, animated: true)
        self.setSectionVisibility(.Recycling, enable: recyclingEnabled, animate: false)
        
        updateDisplay()
        
        if (!logic.initialSetupComplete()) {
            self.fadeOverlay.alpha = 1.0
        }
        
        self.calendarParitySegmentedControl.selectedSegmentIndex = logic.recyclingFrequency()
        self.reminderDaySegmentedControl.selectedSegmentIndex = logic.alertDay()
        
        self.calendarView.scrollToToday(false)
    }
    
    override func viewDidAppear(animated: Bool) {
        if (logic.initialSetupComplete()) {
            UIView.animateWithDuration(kSettingsAnimationDuration,
                animations: {
                    self.fadeOverlay.alpha = 0.0
                }
            )
        }
        else {
            self.performSegueWithIdentifier("showWelcome", sender: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Interface Updates
    
    func updateDisplay() {
        setScheduleButtonLabel()
        setCountdownValues()
    }
    
    func setupImages() {
        self.trashImageView.image = Theme.fillImage(UIImage(named: "Trash")!, color: Theme.Color.Blue)
        self.trashIconButton.setImage(Theme.fillImage(UIImage(named: "Trash Small")!, color: Theme.Color.White), forState: .Normal)
        self.trashSettingsButton.setImage(Theme.fillImage(UIImage(named: "Gear")!, color: Theme.Color.White), forState: .Normal)
        
        self.recycleImageView.image = Theme.fillImage(UIImage(named: "Recycle")!, color: Theme.Color.Green)
        self.recyclingIconButton.setImage(Theme.fillImage(UIImage(named: "Recycle Small")!, color: Theme.Color.White), forState: .Normal)
        self.recyclingSettingsButton.setImage(Theme.fillImage(UIImage(named: "Gear")!, color: Theme.Color.White), forState: .Normal)
    }
    
    func setSectionVisibility(section: SectionType, enable: Bool) {
        setSectionVisibility(section, enable: enable, animate: true)
    }
    func setSectionVisibility(section: SectionType, enable: Bool, animate: Bool) {
        updateDisplay()
        
        UIView.animateWithDuration(
            (animate ? kSettingsAnimationDuration : 0),
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.1,
            options: .TransitionCrossDissolve | .CurveEaseInOut,
            animations: {
                switch section {
                case .Trash:
                    self.trashShadowView.alpha = (enable ? 1 : 0)
                    self.trashImageView.alpha = (enable ? 0 : 1)
                    self.trashCountdownViewLeadingSpace.constant = (enable ? 0 : -self.trashCountdownView.frame.width/4)
                    self.trashCountdownView.alpha = (enable ? 1 : 0)
                    self.trashSettingsButton.enabled = enable
                    self.trashIconButton.enabled = enable
                    self.trashContainerView.backgroundColor = (enable ? Theme.Color.Blue.color() : Theme.Color.White.color())
                case .Recycling:
                    self.recyclingShadowView.alpha = (enable ? 1 : 0)
                    self.recycleImageView.alpha = (enable ? 0 : 1)
                    self.recyclingCountdownViewLeadingSpace.constant = (enable ? 0 : -self.recyclingCountdownView.frame.width/4)
                    self.recyclingCountdownView.alpha = (enable ? 1 : 0)
                    self.recyclingSettingsButton.enabled = enable
                    self.recyclingIconButton.enabled = enable
                    self.recyclingContainerView.backgroundColor = (enable ? Theme.Color.Green.color() : Theme.Color.White.color())
                }
                self.view.layoutIfNeeded()
            },
            completion: {(finished: Bool) in
                switch section {
                case .Trash:
                    if (enable && !self.logic.hasTrashReferenceDate()) {
                        self.showCalendar(self.trashSettingsButton)
                    }
                    
                case .Recycling:
                    if (enable && !self.logic.hasRecyclingReferenceDate()) {
                        self.showCalendar(self.recyclingSettingsButton)
                    }
                    
                }
            }
        )
    }
    
    func setScheduleButtonLabel() {
        if (UIApplication.sharedApplication().currentUserNotificationSettings().types == UIUserNotificationType.None) {
            self.reminderTimeButton.title = "Notifications Disabled"
        }
        else if (self.logic.trashEnabled() || self.logic.recyclingEnabled()) {
            self.reminderTimeButton.title = logic.alertTimeString()
            self.reminderTimeButton.enabled = true
            self.reminderIconButton.enabled = true
        }
        else {
            self.reminderTimeButton.title = "No Reminders Turned On"
            self.reminderTimeButton.enabled = false
            self.reminderIconButton.enabled = false
        }
    }
    
    func setCountdownValues() {
        let trashCountdown = logic.daysUntilCollection(Logic.SectionType.Trash)
        self.trashNextCollectionLabel.text = trashCountdown
        switch trashCountdown {
        case "1": self.trashDaysLabel.text = "DAY"
        default: self.trashDaysLabel.text = "DAYS"
        }
        
        let recyclingCountdown = logic.daysUntilCollection(Logic.SectionType.Recycling)
        self.recyclingNextCollectionLabel.text = recyclingCountdown
        switch recyclingCountdown {
        case "1": self.recyclingDaysLabel.text = "DAY"
        default: self.recyclingDaysLabel.text = "DAYS"
        }
    }
    
    // MARK: - Animation Helpers
    
    func prepareOverlay() {
        self.overlayView.hidden = false
        self.openSettingsButton.enabled = false
        self.trashSettingsButton.enabled = false
        self.recyclingSettingsButton.enabled = false
        self.calendarParitySegmentedControl.alpha = 0
    }
    
    func setOverlayValues() {
        self.overlayView.alpha = 1.0
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
    }
    
    // MARK: - Animations
    
    @IBAction func showCalendar(sender: UIButton) {
        prepareOverlay()
        
        currentSection = SectionType(rawValue: sender.tag)
        
        var calendarType = ""
        switch currentSection {
        case .Some(.Trash):
            if (logic.hasTrashReferenceDate()) {
                self.calendarView.selectDate(logic.trashNextCollection())
            } else {
                self.calendarView.selectDate(nil)
            }
            calendarType = "Trash"
        case .Some(.Recycling):
            if (logic.hasRecyclingReferenceDate()) {
                self.calendarView.selectDate(logic.recyclingNextCollection())
            } else {
                self.calendarView.selectDate(nil)
            }
            calendarType = "Recycling"
        default: break
        }
        
        self.calendarMessageLabel.text = "When is your next \(calendarType) collection?"
        
        UIView.animateWithDuration(kSettingsAnimationDuration,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.3,
            options: .CurveEaseInOut,
            animations: {
                self.calendarVerticalSpace.constant = -self.calendarView.frame.height
                self.setOverlayValues()
                if (sender.tag == SectionType.Recycling.rawValue) {
                    self.calendarParitySegmentedControl.alpha = 1
                }
                self.view.layoutIfNeeded()
            },
            completion: nil
        )
        
        showOverlayImage(.Calendar)
    }
    
    @IBAction func showTimeSelection(sender: UIBarButtonItem) {
        if (UIApplication.sharedApplication().currentUserNotificationSettings().types == UIUserNotificationType.None) {
            if (logic.didRequestNotificationPermission()) {
                UIAlertView(title: "Notifications Disabled", message: "To turn on notifications open the Settings app from your home screen, scroll down until you find Trash Time, and switch notifications on.", delegate: self, cancelButtonTitle: "Okay").show()
            } else {
                Notifications.instance.requestNotificationPermission()
            }
        }
        else if (self.timeSelectionViewVerticalPosition.constant == -self.timeSelectionContainer.frame.height) {
            self.closeOverlay(self)
        }
        else {
            prepareOverlay()
            
            self.scheduleTimePicker.date = logic.alertDate()
            
            UIView.animateWithDuration(kSettingsAnimationDuration,
                delay: 0,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0.1,
                options: .CurveEaseInOut,
                animations: {
                    self.timeSelectionViewVerticalPosition.constant = -self.timeSelectionContainer.frame.height
                    self.setOverlayValues()
                    self.view.layoutIfNeeded()
                },
                completion: nil
            )
            
            showOverlayImage(.TimePicker)
        }
    }
    
    func showOverlayImage(overlayType: OverlayType) {
        UIView.animateWithDuration(kSettingsAnimationDuration*2,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.3,
            options: .CurveEaseOut,
            animations: {
                var verticalPosition: CGFloat = 0
                switch overlayType {
                case .TimePicker:
                    self.overlayImage.image = Theme.fillImage(UIImage(named:"Alarm")!, color: Theme.Color.White)
                    verticalPosition = self.timeSelectionContainer.frame.height + self.scheduleToolbar.frame.height
                case .Calendar:
                    self.overlayImage.image = Theme.fillImage(UIImage(named:"Calendar")!, color: Theme.Color.White)
                    verticalPosition = self.calendarView.frame.height
                }
                
                self.overlaySpacerVerticalPosition.constant = verticalPosition
                self.overlayImage.alpha = 1.0
                self.view.layoutIfNeeded()
            },
            completion: nil
        )
    }
    
    @IBAction func closeOverlay(sender: AnyObject) {
        updateDisplay()
        
        currentSection = nil
        
        UIView.animateWithDuration(kSettingsAnimationDuration,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.1,
            options: .CurveEaseIn,
            animations: {
                self.timeSelectionViewVerticalPosition.constant = 0
                self.overlaySpacerVerticalPosition.constant = self.view.frame.height
                self.calendarVerticalSpace.constant = 0
                self.overlayView.alpha = 0
                self.overlayImage.alpha = 0
                self.calendarParitySegmentedControl.alpha = 0
                self.openSettingsButton.enabled = true
                self.view.layoutIfNeeded()
                UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
            },
            completion: {(finished: Bool) in
                self.overlayView.hidden = true
                self.overlaySpacerVerticalPosition.constant = 0
                self.openSettingsButton.enabled = true
                
                self.trashSettingsButton.enabled = true
                self.recyclingSettingsButton.enabled = true;
                
                if (self.trashSwitch.on && !self.logic.hasTrashReferenceDate()) {
                    self.trashSwitch.setOn(false, animated: true)
                    self.setSectionVisibility(.Trash, enable: false)
                }
                else if (self.recycleSwitch.on && !self.logic.hasRecyclingReferenceDate()) {
                    self.recycleSwitch.setOn(false, animated: true)
                    self.setSectionVisibility(.Recycling, enable: false)
                }
                
                self.calendarView.scrollToToday(false)
            }
        )
        
        Notifications.instance.setupNotifications()
    }
    
    // MARK: - Actions
    
    @IBAction func alertTimingChanged(sender: UISegmentedControl) {
        self.logic.setAlertDay(Logic.AlertDay(rawValue: sender.selectedSegmentIndex)!)
        self.timePickerUpdated(self.scheduleTimePicker)
    }
    
    @IBAction func timePickerUpdated(sender: UIDatePicker) {
        logic.setAlertTime(sender.date)
        self.setScheduleButtonLabel()
    }
    
    
    @IBAction func recyclingParityChanged(sender: UISegmentedControl) {
        logic.setRecyclingFrequencyParity(sender.selectedSegmentIndex)
        self.calendarView.selectDate(logic.recyclingNextCollection())
    }
    
    // MARK: - PopOvers
    
    @IBAction func showCollectionPopOver(sender: UIButton) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        
        var date: NSDate?
        var popOver: AMPopTip?

        switch sender.tag {
        case 1:
            popOver = self.trashPopOver
            date = self.logic.trashNextCollection()
        case 2:
            popOver = self.recyclingPopOver
            date = self.logic.recyclingNextCollection()
        default: break
        }
        
        if (popOver!.isVisible) {
            popOver!.hide()
        }
        else {
            popOver!.showText("Next collection \(dateFormatter.stringFromDate(date!))", direction: AMPopTipDirection.Left, maxWidth: self.view.frame.width * 0.6, inView:sender.superview, fromFrame: sender.frame, duration: 2)
        }
    }
    
    // MARK: - Calendar Delegate
    
    func datePickerView(view: RSDFDatePickerView!, didSelectDate date: NSDate!) {
        switch currentSection {
        case .Some(.Trash):
            logic.setTrashReferenceDate(date)
            self.logic.setSectionEnabled(Logic.SectionType.Trash, enabled: true)
        case .Some(.Recycling):
            logic.setRecyclingReferenceDate(date)
            self.logic.setSectionEnabled(Logic.SectionType.Recycling, enabled: true)
        default: break
        }
    }
    
    // MARK: - Alert View Delegate
    
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        updateDisplay()
    }
    
    // MARK: - Enums
    
    enum OverlayType {
        case TimePicker
        case Calendar
    }
    
    enum SectionType: Int {
        case Trash = 1
        case Recycling
    }
    
    // MARK: - Constants
    
    let kSettingsAnimationDuration = 0.6
    
    // MARK: - Outlets
    
    @IBOutlet weak var trashContainerView: UIView!
    @IBOutlet weak var trashCountdownView: UIView!
    @IBOutlet weak var trashNextCollectionLabel: UILabel!
    @IBOutlet weak var trashShadowView: UIView!
    @IBOutlet weak var trashCountdownViewLeadingSpace: NSLayoutConstraint!
    @IBOutlet weak var trashDaysLabel: UILabel!
    
    @IBOutlet weak var trashImageView: UIImageView!
    @IBOutlet weak var trashIconButton: UIButton!
    @IBOutlet weak var trashSwitch: RAMPaperSwitch!
    @IBOutlet weak var trashSettingsButton: UIButton!
    
    @IBOutlet weak var recyclingContainerView: UIView!
    @IBOutlet weak var recyclingCountdownView: UIView!
    @IBOutlet weak var recyclingNextCollectionLabel: UILabel!
    @IBOutlet weak var recyclingShadowView: UIView!
    @IBOutlet weak var recyclingCountdownViewLeadingSpace: NSLayoutConstraint!
    @IBOutlet weak var recyclingDaysLabel: UILabel!
    
    @IBOutlet weak var recycleImageView: UIImageView!
    @IBOutlet weak var recyclingIconButton: UIButton!
    @IBOutlet weak var recycleSwitch: RAMPaperSwitch!
    @IBOutlet weak var recyclingSettingsButton: UIButton!
    
    // white overlay when loading
    @IBOutlet weak var fadeOverlay: UIView!
    
    // black overlay on main interface
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var overlayImage: UIImageView!
    @IBOutlet weak var overlaySpacerVerticalPosition: NSLayoutConstraint!
    
    @IBOutlet weak var scheduleToolbar: UIToolbar!
    @IBOutlet weak var reminderIconButton: UIBarButtonItem!
    @IBOutlet weak var reminderTimeButton: UIBarButtonItem!
    @IBOutlet weak var openSettingsButton: UIBarButtonItem!
    
    @IBOutlet weak var timeSelectionContainer: UIView!
    @IBOutlet weak var scheduleTimePicker: UIDatePicker!
    @IBOutlet weak var reminderDaySegmentedControl: UISegmentedControl!
    @IBOutlet weak var timeSelectionViewVerticalPosition: NSLayoutConstraint!
    
    @IBOutlet weak var calendarView: RSDFDatePickerView!
    @IBOutlet weak var calendarMessageLabel: UILabel!
    @IBOutlet weak var calendarParitySegmentedControl: UISegmentedControl!
    @IBOutlet weak var calendarVerticalSpace: NSLayoutConstraint!

}


//
//  Logic.swift
//  Trash Time
//
//  Created by Thomas Hajcak on 4/9/15.
//  Copyright (c) 2015 Simple Ink. All rights reserved.
//

import Foundation

public class Logic {
    
    public static let instance = Logic()
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    // MARK: - Switching
    
    // Saves the current state of the UISwitch to the User Defaults.
    public func toggleSection(section: SectionType, toggle: Bool) {
        self.defaults.setBool(toggle, forKey: (section == .Trash ? kTrashEnabled : kRecyclingEnabled))
        self.defaults.synchronize()
    }
    
    // MARK: - Setup
    
    // Sets basic default values for the app to begin start with.
    public func defaultDefaults() {
        if (self.defaults.objectForKey(kScheduledAlertDay) == nil) {
            self.defaults.setInteger(AlertDay.DayBefore.rawValue, forKey: kScheduledAlertDay)
        }
        
        if (self.defaults.objectForKey(kScheduledFrequency) == nil) {
            self.defaults.setInteger(RecyclingFrequency.Weekly.hashValue, forKey: kScheduledFrequency)
        }
        
        if (self.defaults.objectForKey(kDidInitialSetup) == nil) {
            self.defaults.setBool(false, forKey: kDidInitialSetup)
        }
        
        let countKey = "CountKey"
        self.defaults.setInteger(0, forKey: countKey)
        self.defaults.setBool(false, forKey: kDidAskForNotifications)
        
        self.defaults.synchronize()
    }
    
    // Saves section state to User Defaults.
    public func setSectionEnabled(section: SectionType, enabled: Bool) {
        switch section {
        case .Trash:
            self.defaults.setBool(enabled, forKey:self.kTrashEnabled)
        case .Recycling:
            self.defaults.setBool(enabled, forKey:self.kRecyclingEnabled)
        }
        
        self.defaults.synchronize()
        NSNotificationCenter.defaultCenter().postNotificationName(kSetupNotificationMessage, object: nil)
    }
    
    // MARK: - Trash Specific
    
    public func setTrashReferenceDate(referenceDate: NSDate) {
        self.defaults.setObject(referenceDate, forKey: kTrashReferenceDate)
        self.defaults.synchronize()
        
        NSNotificationCenter.defaultCenter().postNotificationName(kSetupNotificationMessage, object: nil)
    }
    
    public func hasTrashReferenceDate() -> Bool {
        return self.defaults.objectForKey(kTrashReferenceDate) != nil
    }
    
    // MARK: - Recycling Specific
    
    public func setRecyclingReferenceDate(referenceDate: NSDate) {
        self.defaults.setObject(referenceDate, forKey: kRecyclingReferenceDate)
        self.defaults.synchronize()
        
        NSNotificationCenter.defaultCenter().postNotificationName(kSetupNotificationMessage, object: nil)
    }
    
    public func hasRecyclingReferenceDate() -> Bool {
        return self.defaults.objectForKey(kRecyclingReferenceDate) != nil
    }
    
    public func setRecyclingFrequencyParity(parity: Int) {
        self.defaults.setInteger(parity, forKey: kScheduledFrequency)
        self.defaults.synchronize()
    }
    
    // MARK: - Alert Setup
    
    public func setAlertTime(date: NSDate) {
        let scheduledTime = NSCalendar.currentCalendar().components(([.Hour, .Minute]), fromDate: date)
        self.defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(scheduledTime), forKey: kScheduledAlertTime)
        self.defaults.synchronize()
    }
    
    public func setAlertDay(alertDay: AlertDay) {
        self.defaults.setInteger(alertDay.hashValue, forKey: kScheduledAlertDay)
        self.defaults.synchronize()
        
    }
    
    public func getWeekdayFromDate(referenceDate: NSDate) -> Int {
        let dateComponents = NSCalendar.currentCalendar().components(NSCalendarUnit.Weekday, fromDate: referenceDate)
        return dateComponents.weekday
    }
    
    public func getWeekParityFromDate(referenceDate: NSDate) -> WeekParity {
        let dateComponents = NSCalendar.currentCalendar().components(NSCalendarUnit.WeekOfYear, fromDate: referenceDate)
        let weekNumber = dateComponents.weekOfYear
        return (weekNumber % 2 == 0 ? .Even : .Odd)
    }
    
    public func getDateReference(type: String) -> NSDate {
        let referenceDate = self.defaults.objectForKey(type) as! NSDate
        return NSCalendar.currentCalendar().dateBySettingUnit(.Weekday, value: getWeekdayFromDate(referenceDate), ofDate: referenceDate, options: [])!
    }
    
    public func setNotificationTime(notificationTime: NSDate) {
        let scheduledTime = NSCalendar.currentCalendar().components(([.Hour, .Minute]), fromDate: notificationTime)
        self.defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(scheduledTime), forKey: kScheduledAlertTime)
        self.defaults.synchronize()
    }
    
    // MARK: - Convienence Getters from User Defaults
    
    public func trashEnabled() -> Bool {
        return self.defaults.boolForKey(kTrashEnabled)
    }
    
    public func trashNextCollection() -> NSDate {
        let reminderDateComponents = self.defaults.objectForKey(kScheduledAlertTime) as? NSData
        let savedReminderTime = NSKeyedUnarchiver.unarchiveObjectWithData(reminderDateComponents!) as! NSDateComponents
        
        var collectionDate = NSCalendar.currentCalendar().dateBySettingHour(savedReminderTime.hour, minute: savedReminderTime.minute, second: 0, ofDate: getDateReference(kTrashReferenceDate), options: [])!
        while (collectionDate.earlierDate(NSDate()) == collectionDate) {
            collectionDate = NSCalendar.currentCalendar().dateByAddingUnit(.WeekOfYear, value: 1, toDate: collectionDate, options: [])!
        }
        return collectionDate
    }
    
    public func recyclingEnabled() -> Bool {
        return self.defaults.boolForKey(kRecyclingEnabled)
    }
    
    public func recyclingNextCollection() -> NSDate {
        let reminderDateComponents = self.defaults.objectForKey(kScheduledAlertTime) as? NSData
        let savedReminderTime = NSKeyedUnarchiver.unarchiveObjectWithData(reminderDateComponents!) as! NSDateComponents
        
        var collectionDate = NSCalendar.currentCalendar().dateBySettingHour(savedReminderTime.hour, minute: savedReminderTime.minute, second: 0, ofDate: getDateReference(kRecyclingReferenceDate), options: [])!
        while (collectionDate.earlierDate(NSDate()) == collectionDate) {
            collectionDate = NSCalendar.currentCalendar().dateByAddingUnit(.WeekOfYear, value: (self.recyclingFrequency()+1), toDate: collectionDate, options: [])!
        }
        return collectionDate
    }
    
    func recyclingParity() -> Int {
        return self.getWeekParityFromDate(self.getDateReference(kRecyclingReferenceDate)).hashValue
    }
    
    public func recyclingFrequency() -> Int {
        return self.defaults.integerForKey(kScheduledFrequency)
    }
    
    public func initialSetupComplete() -> Bool {
        return self.defaults.boolForKey(kDidInitialSetup)
    }
    
    public func alertTimeString() -> String {
        if let reminderDateComponents = self.defaults.objectForKey(kScheduledAlertTime) as? NSData {
            let savedReminderTime = NSKeyedUnarchiver.unarchiveObjectWithData(reminderDateComponents) as! NSDateComponents
            let date = NSCalendar.currentCalendar().dateFromComponents(savedReminderTime)
            
            let timeFormat = NSDateFormatter()
            timeFormat.timeStyle = .ShortStyle
            
            var reminderDay: String
            switch Logic.AlertDay(rawValue: self.defaults.integerForKey(kScheduledAlertDay))! {
            case .DayBefore: reminderDay = "The day before"
            case .DayOf: reminderDay = "The day of"
            }
            
            return "\(reminderDay) at \(timeFormat.stringFromDate(date!))"
        }
        else {
            return "Set Reminder Time"
        }
    }
    
    public func alertDate() -> NSDate {
        if let reminderDateComponents = self.defaults.objectForKey(kScheduledAlertTime) as? NSData {
            let savedReminderTime = NSKeyedUnarchiver.unarchiveObjectWithData(reminderDateComponents) as! NSDateComponents
            return NSCalendar.currentCalendar().dateFromComponents(savedReminderTime)!
        }
        return NSDate()
    }
    
    public func alertDay() -> Int {
        return self.defaults.integerForKey(kScheduledAlertDay)
    }
    
    public func daysUntilCollection(section: SectionType) -> String {
        var collectionDate: NSDate?
        
        if let _ = self.defaults.objectForKey(kScheduledAlertTime) as? NSData {
            switch section {
            case .Trash:
                if let _ = self.defaults.objectForKey(kTrashReferenceDate) as? NSDate {
                    collectionDate = NSCalendar.currentCalendar().dateBySettingHour(23, minute: 59, second: 59, ofDate: getDateReference(kTrashReferenceDate), options: [])
                    while (collectionDate?.earlierDate(NSDate()) == collectionDate) {
                        collectionDate = NSCalendar.currentCalendar().dateByAddingUnit(.WeekOfYear, value: 1, toDate: collectionDate!, options: [])
                    }
                }
            case .Recycling:
                if let _ = self.defaults.objectForKey(kRecyclingReferenceDate) as? NSDate {
                    collectionDate = NSCalendar.currentCalendar().dateBySettingHour(23, minute: 59, second: 59, ofDate: getDateReference(kRecyclingReferenceDate), options: [])
                    while (collectionDate?.earlierDate(NSDate()) == collectionDate) {
                        collectionDate = NSCalendar.currentCalendar().dateByAddingUnit(.WeekOfYear, value: (self.recyclingFrequency()+1), toDate: collectionDate!, options: [])
                    }
                }
            }
        } else {
            return "?"
        }
        
        if let collectionDate = collectionDate as NSDate? {
            let timeInterval = NSCalendar.currentCalendar().components([.Day, .Hour], fromDate: NSDate(), toDate: collectionDate, options: [])
            let today = NSCalendar.currentCalendar().components(.Day, fromDate: NSDate()).day
            let collection = NSCalendar.currentCalendar().components(.Day, fromDate: collectionDate).day
            if (today == collection) {
                return "0"
            } else if (timeInterval.day == 0){
                return "1"
            } else {
                return "\(timeInterval.day)"
            }
        } else {
            return "?"
        }
    }
    
    public func nextCollection() -> (String, Bool, Bool) {
        let trashEnabled = self.trashEnabled()
        let trashHasDateReference = hasTrashReferenceDate()
        
        let recyclingEnabled = self.recyclingEnabled()
        let recyclingHasDateReference = hasRecyclingReferenceDate()
        
        let reminderDateComponents = self.defaults.objectForKey(kScheduledAlertTime) as? NSData
        
        if (reminderDateComponents == nil ||
            (!trashEnabled && !recyclingEnabled) ||
            (trashEnabled && !trashHasDateReference) ||
            (recyclingEnabled && !recyclingHasDateReference)) {
                return ("No alerts enabled", false, false)
        }
        
        var daysToGo = "?"
        let trashCountdown = self.daysUntilCollection(.Trash)
        let recyclingCountdown = self.daysUntilCollection(.Recycling)
        var isTrash = false
        var isRecycling = false
        
        if trashEnabled && recyclingEnabled {
            if trashCountdown == recyclingCountdown {
                daysToGo = trashCountdown
                isTrash = true
                isRecycling = true
            }
            else if Int(trashCountdown) < Int(recyclingCountdown) {
                daysToGo = trashCountdown
                isTrash = true
            }
            else if Int(recyclingCountdown) < Int(trashCountdown) {
                daysToGo = recyclingCountdown
                isRecycling = true
            }
        }
        else if trashEnabled {
            daysToGo = trashCountdown
            isTrash = true
        }
        else if recyclingEnabled {
            daysToGo = recyclingCountdown
            isRecycling = true
        }
        
        switch daysToGo {
        case "?": daysToGo = "unknown"
        case "0": daysToGo = "today"
        case "1": daysToGo = "tomorrow"
        default: daysToGo = "in \(daysToGo) days"
        }
        
        return ("Next Collection \(daysToGo)", isTrash, isRecycling)
    }
    
    public func didRequestNotificationPermission() -> Bool {
        return self.defaults.boolForKey(kDidAskForNotifications)
    }
    
    public func setRequestedNotificationPermission() {
        self.defaults.setBool(true, forKey: kDidAskForNotifications)
        self.defaults.synchronize()
    }
    
    public func getScheduleFrequency() -> Int {
        return self.defaults.integerForKey(kScheduledFrequency)
    }
    
    public func getAlertTime() -> NSData? {
        return self.defaults.objectForKey(kScheduledAlertTime) as? NSData
    }
    
    // MARK: - Application State
    
    public func setWelcomeComplete() {
        self.defaults.setBool(true, forKey: kDidInitialSetup)
        self.defaults.synchronize()
    }
    
    public func forgetEverything() {
        self.defaults.removeObjectForKey(kTrashEnabled)
        self.defaults.removeObjectForKey(kTrashSchedule)
        self.defaults.removeObjectForKey(kTrashReferenceDate)
        self.defaults.removeObjectForKey(kRecyclingEnabled)
        self.defaults.removeObjectForKey(kRecyclingSchedule)
        self.defaults.removeObjectForKey(kRecyclingReferenceDate)
        self.defaults.removeObjectForKey(kScheduledAlertTime)
        self.defaults.removeObjectForKey(kScheduledAlertDay)
        self.defaults.removeObjectForKey(kScheduledBiWeeklyOddEven)
        self.defaults.removeObjectForKey(kScheduledFrequency)
        self.defaults.removeObjectForKey(kDidInitialSetup)
        
        self.defaults.synchronize()
    }
    
    // MARK: - DEBUG
    
    public func addBackgroundRefreshCount() {
        let countKey = "CountKey"
        let count = self.defaults.integerForKey(countKey)
        self.defaults.setInteger(count+1, forKey: countKey)
        self.defaults.synchronize()
    }
    public func getBackgroundRefreshCount() -> Int {
        let countKey = "CountKey"
        return self.defaults.integerForKey(countKey)
    }
    public func resetBackgroundRefreshCount() {
        let countKey = "CountKey"
        self.defaults.setInteger(0, forKey: countKey)
        self.defaults.synchronize()
    }
    
    // MARK: - Constants & Enums
    
    let kTrashEnabled = "TrashEnabled"
    let kTrashSchedule = "TrashSchedule"
    public let kTrashReferenceDate = "TrashReferenceDate"
    
    let kRecyclingEnabled = "RecyclingEnabled"
    let kRecyclingSchedule = "RecyclingSchedule"
    public let kRecyclingReferenceDate = "RecyclingReferenceDate"
    
    let kScheduledAlertTime = "ScheduledTime"
    let kScheduledAlertDay = "ScheduledDay"
    let kScheduledBiWeeklyOddEven = "ScheduledBiWeeklyOddEven"
    let kScheduledFrequency = "RecyclingScheduledFrequency"
    
    let kDidInitialSetup = "InitialSetupComplete"
    let kDidAskForNotifications = "AskedForNotifications"
    let kSetupNotificationMessage = "SetupNotificationMessage"
    
    public enum SectionType {
        case Trash
        case Recycling
    }
    
    public enum AlertDay: Int {
        case DayOf = 0
        case DayBefore
    }
    
    public enum WeekParity {
        case Even
        case Odd
    }
    
    public enum RecyclingFrequency {
        case Weekly
        case BiWeekly
    }
}
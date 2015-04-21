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
    
    let defaults = NSUserDefaults(suiteName: "group.simpleink.TrashTimeShare")!
    
    // MARK: - Switching
    
    public func toggleSection(section: SectionType, toggle: Bool) {
        self.defaults.setBool(toggle, forKey: (section == .Trash ? kTrashEnabled : kRecyclingEnabled))
        self.defaults.synchronize()
    }
    
    // MARK: - Setup
    
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
    
    public func setSectionEnabled(section: SectionType, enabled: Bool) {
        switch section {
        case .Trash:
            self.defaults.setBool(enabled, forKey:self.kTrashEnabled)
        case .Recycling:
            self.defaults.setBool(enabled, forKey:self.kRecyclingEnabled)
        }
        
        self.defaults.synchronize()
        self.setupNotifications()
    }
    
    // MARK: - Trash
    
    public func setTrashReferenceDate(referenceDate: NSDate) {
        self.defaults.setObject(referenceDate, forKey: kTrashReferenceDate)
        self.defaults.synchronize()
        
        self.setupNotifications()
    }
    
    public func hasTrashReferenceDate() -> Bool {
        return self.defaults.objectForKey(kTrashReferenceDate) != nil
    }
    
    // MARK: - Recycling
    
    public func setRecyclingReferenceDate(referenceDate: NSDate) {
        self.defaults.setObject(referenceDate, forKey: kRecyclingReferenceDate)
        self.defaults.synchronize()
        
        self.setupNotifications()
    }
    
    public func hasRecyclingReferenceDate() -> Bool {
        return self.defaults.objectForKey(kRecyclingReferenceDate) != nil
    }
    
    public func setRecyclingFrequencyParity(parity: Int) {
        self.defaults.setInteger(parity, forKey: kScheduledFrequency)
        self.defaults.synchronize()
    }
    
    // MARK: - Alert
    
    public func setAlertTime(date: NSDate) {
        let scheduledTime = NSCalendar.currentCalendar().components((.CalendarUnitHour | .CalendarUnitMinute), fromDate: date)
        self.defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(scheduledTime), forKey: kScheduledAlertTime)
        self.defaults.synchronize()
    }
    
    public func setAlertDay(alertDay: AlertDay) {
        self.defaults.setInteger(alertDay.hashValue, forKey: kScheduledAlertDay)
        self.defaults.synchronize()
        
    }
    
    func getWeekdayFromDate(referenceDate: NSDate) -> Int {
        let dateComponents = NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitWeekday, fromDate: referenceDate)
        return dateComponents.weekday
    }
    
    func getWeekParityFromDate(referenceDate: NSDate) -> WeekParity {
        let dateComponents = NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitWeekOfYear, fromDate: referenceDate)
        let weekNumber = dateComponents.weekOfYear
        return (weekNumber % 2 == 0 ? .Even : .Odd)
    }
    
    func getDateReference(type: String) -> NSDate {
        let referenceDate = self.defaults.objectForKey(type) as! NSDate
        return NSCalendar.currentCalendar().dateBySettingUnit(.CalendarUnitWeekday, value: getWeekdayFromDate(referenceDate), ofDate: referenceDate, options: nil)!
    }
    
    public func setNotificationTime(notificationTime: NSDate) {
        let scheduledTime = NSCalendar.currentCalendar().components((.CalendarUnitHour | .CalendarUnitMinute), fromDate: notificationTime)
        self.defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(scheduledTime), forKey: kScheduledAlertTime)
        self.defaults.synchronize()
    }
    
    // MARK: - Notification
    public func setupNotifications() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), {
            self.createAllNotifications()
        })
    }
    
    func createAllNotifications() {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        
        let trashEnabled = self.trashEnabled()
        let trashHasDateReference = hasTrashReferenceDate()
        
        let recyclingEnabled = self.recyclingEnabled()
        let recyclingHasDateReference = hasRecyclingReferenceDate()
        
        let reminderDateComponents = self.defaults.objectForKey(kScheduledAlertTime) as? NSData
        
        if (reminderDateComponents == nil ||
            (!trashEnabled && !recyclingEnabled) ||
            (trashEnabled && !trashHasDateReference) ||
            (recyclingEnabled && !recyclingHasDateReference)) {
                return
        }
        
        println("Processing Notifications")
        
        var firstTrashDate: NSDate?
        if (trashEnabled && trashHasDateReference) {
            firstTrashDate = trashNextCollection()
        }
        
        var firstRecyclingDate: NSDate?
        if (recyclingEnabled && recyclingHasDateReference) {
            firstRecyclingDate = recyclingNextCollection()
        }
        
        let scheduleFrequency = self.defaults.integerForKey(kScheduledFrequency)
        
        var sameWeekday: Bool {
            get {
                if (trashEnabled && recyclingEnabled) {
                    let trashDay = getWeekdayFromDate(firstTrashDate!)
                    let recyclingDay = getWeekdayFromDate(firstRecyclingDate!)
                    
                    if (trashDay == recyclingDay) {
                        return true;
                    }
                    return false
                }
                else {
                    return true
                }
            }
        }
        
        var currentDate: NSDate?
        if (trashEnabled && recyclingEnabled) {
            currentDate = firstTrashDate!.earlierDate(firstRecyclingDate!)
        } else {
            currentDate = (trashEnabled ? firstTrashDate! : firstRecyclingDate!)
        }
        
        while (currentDate?.earlierDate(NSDate()) == currentDate) {
            currentDate = NSCalendar.currentCalendar().dateByAddingUnit(.CalendarUnitWeekOfYear, value: 1, toDate: currentDate!, options: nil)
        }
        
        var currentDay = NSCalendar.currentCalendar().components(.CalendarUnitWeekday, fromDate: currentDate!).weekday
        
        let trashDay: Int? = (Logic.instance.hasTrashReferenceDate() ? getWeekdayFromDate(getDateReference(kTrashReferenceDate)) : nil)
        let recycleDay: Int? = (Logic.instance.hasRecyclingReferenceDate() ? getWeekdayFromDate(getDateReference(kRecyclingReferenceDate)) : nil)
        
        mainIteration: for var loopIndex = 0; loopIndex < 52; loopIndex++ {
            var localNotification = UILocalNotification()
            localNotification.timeZone = NSCalendar.currentCalendar().timeZone
            localNotification.soundName = UILocalNotificationDefaultSoundName;
            localNotification.fireDate = currentDate!
            
            if (sameWeekday && trashEnabled && recyclingEnabled && currentDate?.laterDate(firstTrashDate!) == currentDate && currentDate?.laterDate(firstRecyclingDate!) == currentDate && (scheduleFrequency == RecyclingFrequency.Weekly.hashValue || (scheduleFrequency == RecyclingFrequency.BiWeekly.hashValue && self.getWeekParityFromDate(currentDate!) == self.getWeekParityFromDate(firstRecyclingDate!)))) {
                localNotification.alertBody = "Time to take out the trash and recycling!"
            }
            else if (trashEnabled && currentDay == trashDay && currentDate?.laterDate(firstTrashDate!) == currentDate) {
                localNotification.alertBody = "Time to take out the trash!"
            }
            else if (recyclingEnabled && currentDay == recycleDay && currentDate?.laterDate(firstRecyclingDate!) == currentDate && (scheduleFrequency == RecyclingFrequency.Weekly.hashValue || (self.defaults.integerForKey(kScheduledFrequency) == RecyclingFrequency.BiWeekly.hashValue && self.getWeekParityFromDate(currentDate!) == self.getWeekParityFromDate(firstRecyclingDate!)))) {
                localNotification.alertBody = "Time to take out the recycling!"
            }
            
            if (sameWeekday || (trashEnabled && !recyclingEnabled) || (!trashEnabled && recyclingEnabled)) {
                currentDate = NSCalendar.currentCalendar().dateByAddingUnit(.CalendarUnitWeekOfYear, value: 1, toDate: currentDate!, options: nil)!
            } else {
                var daysToAdd = 0
                if (currentDay == trashDay) {
                    daysToAdd = recycleDay! - currentDay + (recycleDay! > trashDay! ? 0 : 7)
                } else {
                    daysToAdd = trashDay! - currentDay + (trashDay! > recycleDay! ? 0 : 7)
                }
                currentDate = NSCalendar.currentCalendar().dateByAddingUnit(.CalendarUnitDay, value: daysToAdd, toDate: currentDate!, options: nil)!
            }
            currentDay = NSCalendar.currentCalendar().components(.CalendarUnitWeekday, fromDate: currentDate!).weekday
            
            if (localNotification.alertBody == nil || localNotification.fireDate == nil) {
                continue
            }
            
            switch AlertDay(rawValue: self.alertDay()) {
            case .Some(.DayBefore):
                let adjustedNotificationDate = NSCalendar.currentCalendar().dateByAddingUnit(.CalendarUnitDay, value: -1, toDate: localNotification.fireDate!, options: nil)
                localNotification.fireDate = adjustedNotificationDate
            case .Some(.DayOf): break
            case .None: break
            }
            

            UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
            if UIApplication.sharedApplication().scheduledLocalNotifications.count >= 60 {
                break mainIteration;
            }
        }
    }
    
    // MARK: - Convienence Getters
    
    public func trashEnabled() -> Bool {
        return self.defaults.boolForKey(kTrashEnabled)
    }
    
    public func trashNextCollection() -> NSDate {
        let reminderDateComponents = self.defaults.objectForKey(kScheduledAlertTime) as? NSData
        let savedReminderTime = NSKeyedUnarchiver.unarchiveObjectWithData(reminderDateComponents!) as! NSDateComponents
        
        var collectionDate = NSCalendar.currentCalendar().dateBySettingHour(savedReminderTime.hour, minute: savedReminderTime.minute, second: 0, ofDate: getDateReference(kTrashReferenceDate), options: nil)!
        while (collectionDate.earlierDate(NSDate()) == collectionDate) {
            collectionDate = NSCalendar.currentCalendar().dateByAddingUnit(.CalendarUnitWeekOfYear, value: 1, toDate: collectionDate, options: nil)!
        }
        return collectionDate
    }
    
    public func recyclingEnabled() -> Bool {
        return self.defaults.boolForKey(kRecyclingEnabled)
    }
    
    public func recyclingNextCollection() -> NSDate {
        let reminderDateComponents = self.defaults.objectForKey(kScheduledAlertTime) as? NSData
        let savedReminderTime = NSKeyedUnarchiver.unarchiveObjectWithData(reminderDateComponents!) as! NSDateComponents
        
        var collectionDate = NSCalendar.currentCalendar().dateBySettingHour(savedReminderTime.hour, minute: savedReminderTime.minute, second: 0, ofDate: getDateReference(kRecyclingReferenceDate), options: nil)!
        while (collectionDate.earlierDate(NSDate()) == collectionDate) {
            collectionDate = NSCalendar.currentCalendar().dateByAddingUnit(.CalendarUnitWeekOfYear, value: (self.recyclingFrequency()+1), toDate: collectionDate, options: nil)!
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
            
            var timeFormat = NSDateFormatter()
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
        
        if let reminderDateComponents = self.defaults.objectForKey(kScheduledAlertTime) as? NSData {
            let savedReminderTime = NSKeyedUnarchiver.unarchiveObjectWithData(reminderDateComponents) as! NSDateComponents
            
            switch section {
            case .Trash:
                if let referenceDate = self.defaults.objectForKey(kTrashReferenceDate) as? NSDate {
                    collectionDate = NSCalendar.currentCalendar().dateBySettingHour(savedReminderTime.hour, minute: savedReminderTime.minute, second: 0, ofDate: getDateReference(kTrashReferenceDate), options: nil)
                    while (collectionDate?.earlierDate(NSDate()) == collectionDate) {
                        collectionDate = NSCalendar.currentCalendar().dateByAddingUnit(.CalendarUnitWeekOfYear, value: 1, toDate: collectionDate!, options: nil)
                    }
                }
            case .Recycling:
                if let referenceDate = self.defaults.objectForKey(kRecyclingReferenceDate) as? NSDate {
                    collectionDate = NSCalendar.currentCalendar().dateBySettingHour(savedReminderTime.hour, minute: savedReminderTime.minute, second: 0, ofDate: getDateReference(kRecyclingReferenceDate), options: nil)
                    while (collectionDate?.earlierDate(NSDate()) == collectionDate) {
                        collectionDate = NSCalendar.currentCalendar().dateByAddingUnit(.CalendarUnitWeekOfYear, value: (self.recyclingFrequency()+1), toDate: collectionDate!, options: nil)
                    }
                }
            }
        } else {
            return "?"
        }
        
        if let collectionDate = collectionDate as NSDate? {
            let timeInterval = NSCalendar.currentCalendar().components(.CalendarUnitDay | .CalendarUnitHour, fromDate: NSDate(), toDate: collectionDate, options: nil)
            let today = NSCalendar.currentCalendar().components(.CalendarUnitDay, fromDate: NSDate()).day
            let collection = NSCalendar.currentCalendar().components(.CalendarUnitDay, fromDate: collectionDate).day
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
        
        var firstTrashDate: NSDate?
        if (trashEnabled && trashHasDateReference) {
            firstTrashDate = trashNextCollection()
        }
        
        var firstRecyclingDate: NSDate?
        if (recyclingEnabled && recyclingHasDateReference) {
            firstRecyclingDate = recyclingNextCollection()
        }
        
        let scheduleFrequency = self.defaults.integerForKey(kScheduledFrequency)
        
        var sameWeekday: Bool {
            get {
                if (trashEnabled && recyclingEnabled) {
                    let trashDay = getWeekdayFromDate(firstTrashDate!)
                    let recyclingDay = getWeekdayFromDate(firstRecyclingDate!)
                    
                    if (trashDay == recyclingDay) {
                        return true;
                    }
                    return false
                }
                else {
                    return true
                }
            }
        }
        
        var currentDate: NSDate?
        if (trashEnabled && recyclingEnabled) {
            currentDate = firstTrashDate!.earlierDate(firstRecyclingDate!)
        } else {
            currentDate = (trashEnabled ? firstTrashDate! : firstRecyclingDate!)
        }
        
        while (currentDate?.earlierDate(NSDate()) == currentDate) {
            currentDate = NSCalendar.currentCalendar().dateByAddingUnit(.CalendarUnitWeekOfYear, value: 1, toDate: currentDate!, options: nil)
        }
        
        var currentDay = NSCalendar.currentCalendar().components(.CalendarUnitWeekday, fromDate: currentDate!).weekday
        
        let trashDay: Int? = (Logic.instance.hasTrashReferenceDate() ? getWeekdayFromDate(getDateReference(kTrashReferenceDate)) : nil)
        let recycleDay: Int? = (Logic.instance.hasRecyclingReferenceDate() ? getWeekdayFromDate(getDateReference(kRecyclingReferenceDate)) : nil)
        
        var isTrash = false
        var isRecycling = false;
        
        if (sameWeekday && trashEnabled && recyclingEnabled && currentDate?.laterDate(firstTrashDate!) == currentDate && currentDate?.laterDate(firstRecyclingDate!) == currentDate && (scheduleFrequency == RecyclingFrequency.Weekly.hashValue || (scheduleFrequency == RecyclingFrequency.BiWeekly.hashValue && self.getWeekParityFromDate(currentDate!) == self.getWeekParityFromDate(firstRecyclingDate!)))) {
            isTrash = true
            isRecycling = true
        }
        else if (trashEnabled && currentDay == trashDay && currentDate?.laterDate(firstTrashDate!) == currentDate) {
            isTrash = true
        }
        else if (recyclingEnabled && currentDay == recycleDay && currentDate?.laterDate(firstRecyclingDate!) == currentDate && (scheduleFrequency == RecyclingFrequency.Weekly.hashValue || (self.defaults.integerForKey(kScheduledFrequency) == RecyclingFrequency.BiWeekly.hashValue && self.getWeekParityFromDate(currentDate!) == self.getWeekParityFromDate(firstRecyclingDate!)))) {
            isRecycling = true
        }

        var daysToGo = "?"
        let timeInterval = NSCalendar.currentCalendar().components(.CalendarUnitDay | .CalendarUnitHour, fromDate: NSDate(), toDate: currentDate!, options: nil)
        let today = NSCalendar.currentCalendar().components(.CalendarUnitDay, fromDate: NSDate()).day
        let collection = NSCalendar.currentCalendar().components(.CalendarUnitDay, fromDate: currentDate!).day
        if (today == collection) {
            daysToGo = "today"
        } else if (timeInterval.day == 0){
            daysToGo = "tomorrow"
        } else {
            daysToGo = "in \(timeInterval.day) days"
        }
        
        return ("Next Collection \(daysToGo)", isTrash, isRecycling)
    }
    
    public func didRequestNotificationPermission() -> Bool {
        return self.defaults.boolForKey(kDidAskForNotifications)
    }
    
    public func requestNotificationPermission() {
        UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Sound | .Alert | .Badge, categories: nil))
        UIApplication.sharedApplication().registerForRemoteNotifications()
        self.defaults.setBool(true, forKey: kDidAskForNotifications)
        self.defaults.synchronize()
    }
    
    // MARK: - Setup
    
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
    let kTrashReferenceDate = "TrashReferenceDate"
    
    let kRecyclingEnabled = "RecyclingEnabled"
    let kRecyclingSchedule = "RecyclingSchedule"
    let kRecyclingReferenceDate = "RecyclingReferenceDate"
    
    let kScheduledAlertTime = "ScheduledTime"
    let kScheduledAlertDay = "ScheduledDay"
    let kScheduledBiWeeklyOddEven = "ScheduledBiWeeklyOddEven"
    let kScheduledFrequency = "RecyclingScheduledFrequency"
    
    let kDidInitialSetup = "InitialSetupComplete"
    let kDidAskForNotifications = "AskedForNotifications"
    
    public enum SectionType {
        case Trash
        case Recycling
    }
    
    public enum AlertDay: Int {
        case DayOf = 0
        case DayBefore
    }
    
    enum WeekParity {
        case Even
        case Odd
    }
    
    enum RecyclingFrequency {
        case Weekly
        case BiWeekly
    }
}
//
//  Notifications.swift
//  Trash Time
//
//  Created by Thomas Hajcak on 4/21/15.
//  Copyright (c) 2015 Simple Ink. All rights reserved.
//

import Foundation
import TrashTimeShare

class Notifications : NSObject {
    
    static let instance = Notifications()
    
    let logic = Logic.instance
    
    override init () {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "setupNotifications", name: "SetupNotificationMessage", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Notification
    func setupNotifications() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), {
            self.createAllNotifications()
        })
    }
    
    func createAllNotifications() {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        
        let trashEnabled = logic.trashEnabled()
        let trashHasDateReference = logic.hasTrashReferenceDate()
        
        let recyclingEnabled = logic.recyclingEnabled()
        let recyclingHasDateReference = logic.hasRecyclingReferenceDate()
        
        let reminderDateComponents = logic.getAlertTime()
        
        if (reminderDateComponents == nil ||
            (!trashEnabled && !recyclingEnabled) ||
            (trashEnabled && !trashHasDateReference) ||
            (recyclingEnabled && !recyclingHasDateReference)) {
                return
        }
        
        print("Processing Notifications")
        
        var firstTrashDate: NSDate?
        if (trashEnabled && trashHasDateReference) {
            firstTrashDate = logic.trashNextCollection()
        }
        
        var firstRecyclingDate: NSDate?
        if (recyclingEnabled && recyclingHasDateReference) {
            firstRecyclingDate = logic.recyclingNextCollection()
        }
        
        let scheduleFrequency = logic.getScheduleFrequency()
        
        var sameWeekday: Bool {
            get {
                if (trashEnabled && recyclingEnabled) {
                    let trashDay = logic.getWeekdayFromDate(firstTrashDate!)
                    let recyclingDay = logic.getWeekdayFromDate(firstRecyclingDate!)
                    
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
        
        let alertTime = NSCalendar.currentCalendar().components([.Hour, .Minute], fromDate: self.logic.alertDate())
        currentDate = NSCalendar.currentCalendar().dateBySettingHour(alertTime.hour, minute: alertTime.minute, second: 0, ofDate: currentDate!, options: [])
        
        while (currentDate!.earlierDate(NSDate()) == currentDate) {
            currentDate = NSCalendar.currentCalendar().dateByAddingUnit(.WeekOfYear, value: 1, toDate: currentDate!, options: [])
        }
        
        var currentDay = NSCalendar.currentCalendar().components(.Weekday, fromDate: currentDate!).weekday
        
        let trashDay: Int? = (logic.hasTrashReferenceDate() ? logic.getWeekdayFromDate(logic.getDateReference(logic.kTrashReferenceDate)) : nil)
        let recycleDay: Int? = (logic.hasRecyclingReferenceDate() ? logic.getWeekdayFromDate(logic.getDateReference(logic.kRecyclingReferenceDate)) : nil)
        
        mainIteration: for var loopIndex = 0; loopIndex < 52; loopIndex++ {
            let localNotification = UILocalNotification()
            localNotification.timeZone = NSCalendar.currentCalendar().timeZone
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.fireDate = currentDate!
            
            if (sameWeekday && trashEnabled && recyclingEnabled && currentDate?.laterDate(firstTrashDate!) == currentDate && currentDate?.laterDate(firstRecyclingDate!) == currentDate && (scheduleFrequency == Logic.RecyclingFrequency.Weekly.hashValue || (scheduleFrequency == Logic.RecyclingFrequency.BiWeekly.hashValue && logic.getWeekParityFromDate(currentDate!) == logic.getWeekParityFromDate(firstRecyclingDate!)))) {
                localNotification.alertBody = "Time to take out the trash and recycling!"
            }
            else if (trashEnabled && currentDay == trashDay && currentDate?.laterDate(firstTrashDate!) == currentDate) {
                localNotification.alertBody = "Time to take out the trash!"
            }
            else if (recyclingEnabled && currentDay == recycleDay && currentDate?.laterDate(firstRecyclingDate!) == currentDate && (scheduleFrequency == Logic.RecyclingFrequency.Weekly.hashValue || (scheduleFrequency == Logic.RecyclingFrequency.BiWeekly.hashValue && logic.getWeekParityFromDate(currentDate!) == logic.getWeekParityFromDate(firstRecyclingDate!)))) {
                localNotification.alertBody = "Time to take out the recycling!"
            }
            
            if (sameWeekday || (trashEnabled && !recyclingEnabled) || (!trashEnabled && recyclingEnabled)) {
                currentDate = NSCalendar.currentCalendar().dateByAddingUnit(.WeekOfYear, value: 1, toDate: currentDate!, options: [])!
            } else {
                var daysToAdd = 0
                if (currentDay == trashDay) {
                    daysToAdd = recycleDay! - currentDay + (recycleDay! > trashDay! ? 0 : 7)
                } else {
                    daysToAdd = trashDay! - currentDay + (trashDay! > recycleDay! ? 0 : 7)
                }
                currentDate = NSCalendar.currentCalendar().dateByAddingUnit(.Day, value: daysToAdd, toDate: currentDate!, options: [])!
            }
            currentDay = NSCalendar.currentCalendar().components(.Weekday, fromDate: currentDate!).weekday
            
            if (localNotification.alertBody == nil || localNotification.fireDate == nil) {
                continue
            }
            
            switch Logic.AlertDay(rawValue: logic.alertDay()) {
            case .Some(.DayBefore):
                let adjustedNotificationDate = NSCalendar.currentCalendar().dateByAddingUnit(.Day, value: -1, toDate: localNotification.fireDate!, options: [])
                localNotification.fireDate = adjustedNotificationDate
            case .Some(.DayOf): break
            case .None: break
            }
            
            if localNotification.fireDate?.earlierDate(NSDate()) == localNotification.fireDate {
                return
            }
            
            
            UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
            if UIApplication.sharedApplication().scheduledLocalNotifications!.count >= 60 {
                break mainIteration;
            }
        }
        
        let endOfNotificationsAlert = UILocalNotification()
        endOfNotificationsAlert.timeZone = NSCalendar.currentCalendar().timeZone
        endOfNotificationsAlert.soundName = UILocalNotificationDefaultSoundName
        endOfNotificationsAlert.fireDate = NSCalendar.currentCalendar().dateByAddingUnit(.Day, value: -6, toDate: currentDate!, options: [])!
        endOfNotificationsAlert.alertBody = "WARNING! You won't receive any additional notifications until you open me."
        UIApplication.sharedApplication().scheduleLocalNotification(endOfNotificationsAlert)
    }
    
    func requestNotificationPermission() {
        UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Sound, .Alert, .Badge], categories: nil))
        UIApplication.sharedApplication().registerForRemoteNotifications()
        logic.setRequestedNotificationPermission()
    }
}
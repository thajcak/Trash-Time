//
//  DebugTableViewController.swift
//  Trash Time
//
//  Created by Thomas Hajcak on 4/14/15.
//  Copyright (c) 2015 Simple Ink. All rights reserved.
//

import UIKit

class DebugTableViewController: UITableViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UIApplication.sharedApplication().scheduledLocalNotifications.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Total Notifications: \(UIApplication.sharedApplication().scheduledLocalNotifications.count)"
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("LocalNotificationsCell", forIndexPath: indexPath) as! UITableViewCell
        
        let thisNotification = UIApplication.sharedApplication().scheduledLocalNotifications[indexPath.row] as! UILocalNotification
        cell.textLabel?.text = thisNotification.alertBody
        cell.detailTextLabel?.text = "\(thisNotification.fireDate!)"
        
        return cell
    }
}
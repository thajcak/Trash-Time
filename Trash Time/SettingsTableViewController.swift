//
//  SettingsTableViewController.swift
//  Trash Time
//
//  Created by Thomas Hajcak on 4/9/15.
//  Copyright (c) 2015 Simple Ink. All rights reserved.
//

import UIKit
import TrashTimeShare

class SettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var backgroundRefreshCount: UILabel!
    
    var overlayView = UIView()
    var calendarView = RSDFDatePickerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
        self.backgroundRefreshCount.text = "\(Logic.instance.getBackgroundRefreshCount())"
    }
    
    override func viewDidAppear(animated: Bool) {
        self.overlayView = UIView(frame: CGRectMake(0, 0, self.view.frame.width, self.view.frame.height))
        self.overlayView.backgroundColor = Theme.Color.White.color()
        self.overlayView.alpha = 0
        self.overlayView.hidden = true
        self.navigationController?.view.addSubview(self.overlayView)
        
        let calendarViewHeight = self.view.frame.height * 0.4
        self.calendarView = RSDFDatePickerView(frame: CGRectMake(0, self.view.frame.height, self.view.frame.width, calendarViewHeight))
        self.navigationController?.view.addSubview(self.calendarView)
    }
    
    @IBAction func closeSettings(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func showHelp(sender: AnyObject) {
        SupportKit.show()
    }
    
    @IBAction func resetSettings(sender: AnyObject) {
        Logic.instance.forgetEverything()
        
        closeSettings(self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier {
        case .Some("showTrashSchedule"):
            let destination = segue.destinationViewController as! UIViewController
            destination.title = "Trash"
        case .Some("showRecyclingSchedule"):
            self.navigationController?.setToolbarHidden(false, animated: true)
            let destination = segue.destinationViewController as! UIViewController
            destination.title = "Recycling"
        default:
            break
        }
    }
    
    // MARK: - Table View Delegate
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0: return "Build \(NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String)!)"
        default: return nil
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}
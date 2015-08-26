//
//  SettingsTableViewController.swift
//  Trash Time
//
//  Created by Thomas Hajcak on 4/9/15.
//  Copyright (c) 2015 Simple Ink. All rights reserved.
//

import UIKit
import StoreKit
import TrashTimeShare

class SettingsTableViewController: UITableViewController, SKStoreProductViewControllerDelegate {
    
    @IBOutlet weak var backgroundRefreshCount: UILabel!
    
    var overlayView = UIView()
    var calendarView = RSDFDatePickerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
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
    
    func showHelp() {
        SupportKit.show()
    }
    
    func showStoreView() {
        let storeViewController = SKStoreProductViewController()
        storeViewController.loadProductWithParameters([SKStoreProductParameterITunesItemIdentifier : "986001359"], completionBlock: nil)
        storeViewController.delegate = self
        self.presentViewController(storeViewController, animated: true, completion: nil);
    }

    func resetSettings() {
        Logic.instance.forgetEverything()
        
        closeSettings(self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier {
        case .Some("showTrashSchedule"):
            let destination = segue.destinationViewController as UIViewController
            destination.title = "Trash"
        case .Some("showRecyclingSchedule"):
            self.navigationController?.setToolbarHidden(false, animated: true)
            let destination = segue.destinationViewController as UIViewController
            destination.title = "Recycling"
        default:
            break
        }
    }
    
    // MARK: - StoreKit Delegate
    func productViewControllerDidFinish(viewController: SKStoreProductViewController) {
        viewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0:
            showHelp()
        case 1:
            showStoreView()
        case 2:
            resetSettings()
        default: break
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 2: return "Trash Time v1 (\(NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String)!))"
        default: return nil
        }
    }
}
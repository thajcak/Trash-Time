//
//  TodayViewController.swift
//  Today
//
//  Created by Thomas Hajcak on 4/17/15.
//  Copyright (c) 2015 Simple Ink. All rights reserved.
//

import UIKit
import NotificationCenter
import TrashTimeShare

class TodayViewController: UIViewController, NCWidgetProviding {
        
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.preferredContentSize = CGSizeMake(0, 37);
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateLabels", name: NSUserDefaultsDidChangeNotification, object: nil)
        
//        updateLabels()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        updateLabels()
//        Logic.instance.setupNotifications()
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets:UIEdgeInsets) -> (UIEdgeInsets) {
        return UIEdgeInsetsMake(2.0, defaultMarginInsets.left, 2.0, defaultMarginInsets.right)
    }
    
    func updateLabels() {
        let nextCollectionInfo = Logic.instance.nextCollection()
        self.nextCollection.text = nextCollectionInfo.0
        
        self.trashIcon.image = Theme.fillImage(self.trashIcon.image!, color: (nextCollectionInfo.1 ? Theme.Color.White : Theme.Color.Black))
        self.recyclingIcon.image = Theme.fillImage(self.recyclingIcon.image!, color: (nextCollectionInfo.2 ? Theme.Color.White : Theme.Color.Black))
    }
    
    @IBOutlet weak var trashIcon: UIImageView!
    @IBOutlet weak var recyclingIcon: UIImageView!
    @IBOutlet weak var nextCollection: UILabel!
}

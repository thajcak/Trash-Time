//
//  AppDelegate.swift
//  Trash Time
//
//  Created by Thomas Hajcak on 4/8/15.
//  Copyright (c) 2015 Simple Ink. All rights reserved.
//

import UIKit
import Crashlytics
import TrashTimeShare

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        Crashlytics.startWithAPIKey("28c8692e863cd8d9f1f9575ab4245e49da550d33")
        
        SupportKit.initWithSettings(SKTSettings(appToken: "ap4bo8nsogtgswrceau24y3ti"))
        
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        Notifications()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        Logic.instance.resetBackgroundRefreshCount()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        NSNotificationCenter.defaultCenter().postNotificationName("ENTERED_FOREGROUND", object: nil);
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        Logic.instance.addBackgroundRefreshCount()
//        UIApplication.sharedApplication().applicationIconBadgeNumber = Logic.instance.getBackgroundRefreshCount()
        Notifications.instance.setupNotifications()
        completionHandler(UIBackgroundFetchResult.NoData)
    }

}


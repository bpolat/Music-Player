//
//  AppDelegate.swift
//  Music Player
//
//  Created by polat on 19/08/14.
//  Copyright (c) 2014 polat. All rights reserved.
// contact  bpolat@live.com


import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?
    var storyboard: UIStoryboard?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
            
        self.window = UIWindow() //window doesn't have an init with frame class, so we need to set that to the screen bounds in order to have touch
        self.window!.frame = UIScreen.mainScreen().bounds
            let iOSDeviceScreenSize = UIScreen.mainScreen().bounds.size
            if iOSDeviceScreenSize.height == 480{
            // Load iPhone 3.x-4.x screen size Storyboard
            self.storyboard = UIStoryboard(name: "Main_3.5_Inch", bundle: nil)
            self.window!.rootViewController = self.storyboard!.instantiateInitialViewController() as? UIViewController
            } else if iOSDeviceScreenSize.height == 568{
                //Load iPhone 5.x screen size Storyboard
                self.storyboard = UIStoryboard(name: "Main_4.0_Inch", bundle: nil)
                self.window!.rootViewController = self.storyboard!.instantiateInitialViewController() as? UIViewController
            
            }else if iOSDeviceScreenSize.height == 667 {
                //Load iPhone 6 screensize Storyboard
                self.storyboard = UIStoryboard(name: "Main_4.7_Inch", bundle: nil)
                self.window!.rootViewController = self.storyboard!.instantiateInitialViewController() as? UIViewController
            }
        
        self.window!.makeKeyAndVisible() //got to manually key since we're initializing our window by hand
        //at this point we have the iPad storyboard or the iPhone storyboard loaded
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}


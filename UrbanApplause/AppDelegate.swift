//
//  AppDelegate.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2018-12-31.
//  Copyright © 2018 Flannery Jefferson. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications
import Shared

let log = DHLogger.self

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let center = UNUserNotificationCenter.current()
    let locationManager = CLLocationManager()
    static let geoCoder = CLGeocoder()
    var window: UIWindow?
    let appContext: AppContext = AppContext()
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // FirebaseConfiguration.shared.setLoggerLevel(FirebaseLoggerLevel.min)
        // FirebaseApp.configure()
        
        appContext.delegate = self
        appContext.sharedApplication = UIApplication.shared
        #if DEBUG
        log.debug("debug")
        #else
        log.debug("release")
        #endif
        
        // UserDefaults.setBiometricPreference(preference: .none)
        // KeychainService().clear(itemAt: KeychainItem.credentials.userAccount)
        let rootViewController = LoadingViewController()
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
        
        appContext.start()
        
        return true
    }
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        report_memory()
        appContext.fileCache.clearUnusedImages()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func report_memory() {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            log.info("Memory used in bytes: \(taskInfo.resident_size)")
        }
        else {
            log.info("Error with task_info(): " +
                (String(cString: mach_error_string(kerr), encoding: String.Encoding.ascii) ?? "unknown error"))
        }
    }
    
}
extension AppDelegate: AppContextDelegate {
    func appContext(setRootController controller: UIViewController) {
        self.window?.rootViewController = controller
    }
}

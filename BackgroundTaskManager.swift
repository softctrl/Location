//
//  BackgroundTaskManager.swift
//  LocationSwing
//
//  Created by Mazhar Biliciler on 14/07/14.
//  Copyright (c) 2014 Mazhar Biliciler. All rights reserved.
//

import Foundation
import UIKit


class BackgroundTaskManager : NSObject {
    
    var bgTaskIdList : NSMutableArray?
    var masterTaskId : UIBackgroundTaskIdentifier?
    
    override init() {

        super.init()
        self.bgTaskIdList = NSMutableArray()
        self.masterTaskId = UIBackgroundTaskInvalid

    }
    
    static var SHARED_BG_MANAGER : BackgroundTaskManager? = BackgroundTaskManager()
    
    class func sharedBackgroundTaskManager() -> BackgroundTaskManager? {
        return BackgroundTaskManager.SHARED_BG_MANAGER
    }
    
    func beginNewBackgroundTask() -> UIBackgroundTaskIdentifier? {
        let application : UIApplication = UIApplication.shared
        
        var bgTaskId : UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
        
        if application.responds(to: Selector(("beginBackgroundTask"))) {
            print("RESPONDS TO SELECTOR")
            bgTaskId = application.beginBackgroundTask(expirationHandler: {
                print("background task \(bgTaskId as Int) expired\n")
            })
        }
        
        if self.masterTaskId == UIBackgroundTaskInvalid {
            self.masterTaskId = bgTaskId
            print("started master task \((self.masterTaskId)!)\n")
        } else {
            // add this ID to our list
            print("started background task \(bgTaskId as Int)\n")
            self.bgTaskIdList!.add(bgTaskId)
            //self.endBackgr
        }
        return bgTaskId
    }
    
    func endBackgroundTask(){
        self.drainBGTaskList(all: false)
    }
    
    func endAllBackgroundTasks() {
        self.drainBGTaskList(all: true)
    }
    
    func drainBGTaskList(all:Bool) {
        //mark end of each of our background task
        let application: UIApplication = UIApplication.shared

        let endBackgroundTask : Selector = #selector(BackgroundTaskManager.endBackgroundTask)

        if application.responds(to: endBackgroundTask) {
            let count: Int = self.bgTaskIdList!.count-1
            let i = (all==true ? 0:1)
            for _ in i...count {
                let bgTaskId : UIBackgroundTaskIdentifier = self.bgTaskIdList!.object(at: 0) as! Int
                print("ending background task with id \(bgTaskId as Int)\n")
                application.endBackgroundTask(bgTaskId)
                self.bgTaskIdList!.removeObject(at: 0)
            }
            if self.bgTaskIdList!.count > 0 {
                print("kept background task id \(self.bgTaskIdList!.object(at: 0))\n")
            }
            if all == true {
                print("no more background tasks running\n")
                application.endBackgroundTask(self.masterTaskId!)
                self.masterTaskId = UIBackgroundTaskInvalid
            } else {
                print("kept master background task id \((self.masterTaskId)!)\n")
            }
        }
    }
    
}

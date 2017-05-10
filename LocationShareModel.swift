//
//  LocationShareModel.swift
//  LocationSwing
//
//  Created by Mazhar Biliciler on 18/07/14.
//  Copyright (c) 2014 Mazhar Biliciler. All rights reserved.
//

import Foundation
import UIKit

class LocationShareModel : NSObject {
    var timer : Timer?
    var bgTask : BackgroundTaskManager?
    var myLocationArray : NSMutableArray?
    
    static let SHARED_MODEL = LocationShareModel()
    
    func sharedModel()-> LocationShareModel {
        return LocationShareModel.SHARED_MODEL
    }
}

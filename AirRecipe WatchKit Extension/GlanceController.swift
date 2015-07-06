//
//  GlanceController.swift
//  AirRecipe WatchKit Extension
//
//  Created by Fuji on 2015/05/27.
//  Copyright (c) 2015年 FromF. All rights reserved.
//

import WatchKit
import Foundation


class GlanceController: WKInterfaceController {

    //Keys
    let CatalogSlectImageName:String = "SlectImageName"
    //UI
    @IBOutlet weak var imageView: WKInterfaceImage!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        
        WKInterfaceController.openParentApplication(["getinfo": ""],
            reply: {replyInfo, error in
                //self.propertyDictionary.removeAll(keepCapacity: false)
                var relyInfokeys = Array(replyInfo.keys)
                for relyInfokey in relyInfokeys {
                    if relyInfokey == self.CatalogSlectImageName {
                        let imagename:String = replyInfo["\(relyInfokey)"] as! String + "_Watch.jpg"
                        self.imageView.setImage(UIImage(named: imagename))
                    }
                }
        })
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}

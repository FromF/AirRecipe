//
//  InterfaceController.swift
//  AirRecipe WatchKit Extension
//
//  Created by Fuji on 2015/05/27.
//  Copyright (c) 2015年 FromF. All rights reserved.
//

import WatchKit
import Foundation
import CoreLocation


class InterfaceController: WKInterfaceController ,CLLocationManagerDelegate , OLYCameraLiveViewDelegate , OLYCameraConnectionDelegate {
    //Tags
    let CatalogSelectNumber:String = "SelectNumber"
    //CoreLocation Serivce
    var locationManager = CLLocationManager()
    //CameraKit
    var camera = OLYCamera()
    //CameraProperty
    var propertyDictionary = [
        "TAKEMODE":"<TAKEMODE/iAuto>",
        "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
    ]
    //LiveViewCounter
    var liveviewCount : NSInteger = 0
    //Clips Mode Flag
    var isClipsMovie : Bool = false
    //HDR Mode Flag
    var isHDRShooting : Bool = false
    //AF Point Center Flag
    var isAFPointCenter : Bool = false
    //CameraKitWrapper
    let cameraWrapper = CameraKitWrapper()
    //UI
    @IBOutlet weak var imageView: WKInterfaceImage!
    @IBOutlet weak var Button: WKInterfaceButton!
    
    override init() {
        super.init()
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        //接続処理
        connectSequence()
        //CoreLocation Serivce
        locationManager.delegate = self
        locationManager.distanceFilter = 500.0
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .AuthorizedAlways, .AuthorizedWhenInUse:
                locationManager.startUpdatingLocation()
                break
            default:
                break
            }
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        //切断処理
        disconnect()
        //CoreLocation Serivce
        locationManager.stopUpdatingLocation()
    }

    //MARK:- ButtonAction
    @IBAction func ButtonAction() {
        if (camera.connected) {
            takePicture()
        } else {
            connectSequence()
        }
    }
    
    func ButtonUpdate() {
        dispatch_async(dispatch_get_main_queue()) {
            if (self.camera.connected) {
                self.Button.setEnabled(true)
                var actionType :OLYCameraActionType = self.camera.actionType()
                if (actionType.value == OLYCameraActionTypeMovie.value) {
                    if (!self.isClipsMovie) {
                        if (self.camera.recordingVideo) {
                            self.Button.setTitle("Stop")
                        } else {
                            self.Button.setTitle("Rec")
                        }
                    } else {
                        self.Button.setTitle("Rec")
                    }
                } else {
                    self.Button.setTitle("Shutter")
                }
            } else {
                self.Button.setEnabled(true)
                self.Button.setTitle("Connect")
            }
        }
    }

    //MARK:- Connect Sequence
    func connectSequence() {
        //ボタンを無効にする
        imageView.setImage(nil)
        Button.setEnabled(false)
        Button.setTitle("Connecting")
        
        self.camera.liveViewDelegate = self
        self.camera.connectionDelegate = self
        
        WKInterfaceController.openParentApplication(["getinfo": ""],
            reply: {replyInfo, error in
                //self.propertyDictionary.removeAll(keepCapacity: false)
                var index:NSInteger = 0
                var relyInfokeys = Array(replyInfo.keys)
                for relyInfokey in relyInfokeys {
                    if relyInfokey == self.CatalogSelectNumber {
                        //index値格納
                        index = (replyInfo["\(relyInfokey)"] as! String).toInt()!
                    }
                }
                self.connectOPC(index)
        })
    }
    
    func connectOPC(index:NSInteger) {
        cameraWrapper.connectOPC(index, camera: camera)
        self.ButtonUpdate()
    }
    
    func disconnect() {
        imageView.setImage(nil)
        cameraWrapper.disconnect(camera)
        ButtonUpdate()
    }
    
    func takePicture() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            dispatch_async(dispatch_get_main_queue(), {
                self.Button.setEnabled(false)
            })
            
            self.cameraWrapper.takePicture(self.camera)
            
            dispatch_async(dispatch_get_main_queue(), {
                self.Button.setEnabled(true)
            })
        })
    }
    
    //MARK:- liveview
    func camera(camera: OLYCamera!, didUpdateLiveView data: NSData!, metadata: [NSObject : AnyObject]!) {
        if (liveviewCount == 0) {
            var image : UIImage = OLYCameraConvertDataToImage(data,metadata)
            dispatch_async(dispatch_get_main_queue()) {
                //リサイズする
                var size = CGSizeMake((image.size.width * 0.1),(image.size.height * 0.1))
                if camera.actionType().value == OLYCameraActionTypeMovie.value {
                    size = CGSizeMake((image.size.width * 0.05),(image.size.height * 0.05))
                }
                UIGraphicsBeginImageContext(size)
                image.drawInRect(CGRectMake(0, 0, size.width, size.height))
                let image_reized : UIImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                //
                self.imageView.setImage(image_reized)
                return
            }
        }
        liveviewCount++;
        if (liveviewCount > 3) {
            liveviewCount = 0;
        }
    }

    //MARK:- disconnect
    func camera(camera: OLYCamera!, disconnectedByError error: NSError!) {
        disconnect()
    }
    
    //MARK:- CoreLocation
    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
        if camera.connected {
            self.cameraWrapper.setGeoLocation(camera, location: newLocation)
        }
    }
}

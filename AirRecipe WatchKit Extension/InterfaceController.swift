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
    //HDR Mode Flag
    var isHDRShooting : Bool = false
    //UI
    @IBOutlet weak var imageView: WKInterfaceImage!
    @IBOutlet weak var Button: WKInterfaceButton!
    
    override init() {
        super.init()
        
        //CoreLocation Serivce
        locationManager.delegate = self
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
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        connectSequence()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
        disconnect()
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
                    if (self.camera.recordingVideo) {
                        self.Button.setTitle("Stop")
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
        
        WKInterfaceController.openParentApplication(["getinfo": ""],
            reply: {replyInfo, error in
                //self.propertyDictionary.removeAll(keepCapacity: false)
                var relyInfokeys = Array(replyInfo.keys)
                for relyInfokey in relyInfokeys {
                    if relyInfokey == self.CatalogSelectNumber {
                        let index:NSInteger! = (replyInfo["\(relyInfokey)"] as! String).toInt()
                        self.isHDRShooting = false   //基本はHDR撮影ではない

                        switch(index) {
                        case 0: //SINGLE_IMG
                            self.propertyDictionary = [
                                "TAKEMODE":"<TAKEMODE/iAuto>",
                                "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                            ]
                            
                        case 1: //CONTINUOUS_IMG
                            self.propertyDictionary = [
                                "TAKEMODE":"<TAKEMODE/iAuto>",
                                "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_CONTINUE>",
                            ]
                            
                        case 2: //MOVIE_IMG
                            self.propertyDictionary = [
                                "TAKEMODE":"<TAKEMODE/movie>",
                            ]
                            
                        case 3: //HDR_IMG
                            self.propertyDictionary = [
                                "TAKEMODE":"<TAKEMODE/A>",
                                "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                                "APERTURE":"<APERTURE/8.0>",
                                "RAW":"<RAW/ON>",
                            ]
                            self.isHDRShooting = true    //HDR撮影
                            
                        default:
                            self.propertyDictionary = [
                                "TAKEMODE":"<TAKEMODE/iAuto>",
                                "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                            ]
                            
                        }
                        
                    }
                }
                println(self.propertyDictionary)
                self.connectOPC()
        })
    }
    
    func connectOPC() {
        var result : Bool = true
        
        if ((result) && (!self.camera.connected)) {
            result = self.camera.connect(OLYCameraConnectionTypeWiFi, error: nil)
        }
        if ((result) && (self.camera.connected)) {
            self.camera.liveViewDelegate = self
            self.camera.autoStartLiveView = false
            result = self.camera.changeRunMode(OLYCameraRunModeRecording, error: nil)
        }
        if ((result) && (self.camera.connected)) {
            result = self.camera.setCameraPropertyValues(self.propertyDictionary, error: nil)
        }
        if ((result) && (self.camera.connected)) {
            result = self.camera.startLiveView(nil)
        }
        self.ButtonUpdate()
    }
    
    func disconnect() {
        imageView.setImage(nil)
        
        if (camera.connected) {
            camera.disconnectWithPowerOff(false, error: nil)
        }
        ButtonUpdate()
    }
    
    
    func takePicture() {
        let actionType :OLYCameraActionType = self.camera.actionType()

        if (self.isHDRShooting) {
            dispatch_async(dispatch_get_main_queue()) {
                self.Button.setEnabled(false)
            }
            
            camera.lockAutoExposure(nil)
            camera.setCameraPropertyValue("EXPREV", value: "+2.0", error: nil)
            camera.takePicture(nil, progressHandler: nil, completionHandler:{info in {
                dispatch_async(dispatch_get_main_queue()) {
                    self.camera.setCameraPropertyValue("EXPREV", value: "0.0", error: nil)
                    self.camera.takePicture(nil, progressHandler: nil, completionHandler:{info in {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.camera.setCameraPropertyValue("EXPREV", value: "-2.0", error: nil)
                            self.camera.takePicture(nil, progressHandler: nil, completionHandler:{info in {
                                dispatch_async(dispatch_get_main_queue()) {
                                    self.camera.setCameraPropertyValue("EXPREV", value: "0.0", error: nil)
                                    self.camera.unlockAutoExposure(nil)
                                    self.Button.setEnabled(true)
                                }
                                }}, errorHandler: nil)
                        }
                        }}, errorHandler: nil)
                }
                }}, errorHandler: nil)
            
        } else if (actionType.value == OLYCameraActionTypeSingle.value) {
            dispatch_async(dispatch_get_main_queue()) {
                self.Button.setEnabled(false)
            }
            camera.takePicture(nil, progressHandler: nil, completionHandler:{info in {
                dispatch_async(dispatch_get_main_queue()) {
                    self.ButtonUpdate()
                }
                }}, errorHandler: nil)
        } else if (actionType.value == OLYCameraActionTypeSequential.value) {
            dispatch_async(dispatch_get_main_queue()) {
                self.Button.setEnabled(false)
            }
            camera.startTakingPicture(nil, progressHandler: nil, completionHandler: {
                dispatch_async(dispatch_get_main_queue()) {
                    self.ButtonUpdate()
                }
            }, errorHandler: nil)
        } else if (actionType.value == OLYCameraActionTypeMovie.value) {
            if (camera.recordingVideo) {
                camera.stopRecordingVideo( { info in
                    self.ButtonUpdate()
                    }, errorHandler: nil)
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.Button.setEnabled(false)
                }
                camera.startRecordingVideo(nil, completionHandler: {
                    self.ButtonUpdate()
                    }, errorHandler: nil)
            }
        }
    }
    
    //MARK:- liveview
    func camera(camera: OLYCamera!, didUpdateLiveView data: NSData!, metadata: [NSObject : AnyObject]!) {
        if (liveviewCount == 0) {
            var image : UIImage = OLYCameraConvertDataToImage(data,metadata)
            dispatch_async(dispatch_get_main_queue()) {
                //リサイズする
                var size = CGSizeMake((image.size.width * 0.1),(image.size.height * 0.1))
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
        let lat = newLocation.coordinate.latitude
        let lng = newLocation.coordinate.longitude
        let coordinate = CLLocationCoordinate2DMake(lat, lng)

    }
}

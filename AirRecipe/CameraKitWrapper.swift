//
//  CameraKitWrapper.swift
//  AirRecipe
//
//  Created by Fuji on 2015/07/01.
//  Copyright (c) 2015年 FromF. All rights reserved.
//

//import Cocoa

class CameraKitWrapper: NSObject {
    //Clips Mode Flag
    var isClipsMovie : Bool = false
    //HDR Mode Flag
    var isHDRShooting : Bool = false
    //AF Point Center Flag
    var isAFPointCenter : Bool = false
    //CameraProperty
    var propertyDictionary = [
        "TAKEMODE":"<TAKEMODE/iAuto>",
        "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
    ]

    func connectOPC(index:NSInteger , camera:OLYCamera) {
        var result : Bool = true
        
        if ((result) && (!camera.connected)) {
            result = camera.connect(OLYCameraConnectionTypeWiFi, error: nil)
        }
        if ((result) && (camera.connected)) {
            camera.autoStartLiveView = false
            result = camera.changeRunMode(OLYCameraRunModeRecording, error: nil)
        }
        if ((result) && (camera.connected)) {
            self.isHDRShooting = false  //基本はHDR撮影ではない
            self.isClipsMovie = false   //基本はClips動画ではない
            self.isAFPointCenter = false    //基本はAF位置がセンターではない
            
            switch(index) {
            case 0: //SINGLE_IMG
                self.propertyDictionary = [
                    "TAKEMODE":"<TAKEMODE/iAuto>",
                    "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                    "RECVIEW":"<RECVIEW/OFF>",
                ]
                
            case 1: //CONTINUOUS_IMG
                self.propertyDictionary = [
                    "TAKEMODE":"<TAKEMODE/iAuto>",
                    "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_CONTINUE>",
                    "RECVIEW":"<RECVIEW/OFF>",
                ]
                
            case 2: //MOVIE_IMG
                self.propertyDictionary = [
                    "TAKEMODE":"<TAKEMODE/movie>",
                    "QUALITY_MOVIE":"<QUALITY_MOVIE/QUALITY_MOVIE_SHORT_MOVIE>",
                ]
                self.isClipsMovie = true    //Clips動画
                
            case 3: //HDR_IMG
                self.propertyDictionary = [
                    "TAKEMODE":"<TAKEMODE/A>",
                    "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                    "APERTURE":"<APERTURE/8.0>",
                    //"RAW":"<RAW/ON>",
                    "RECVIEW":"<RECVIEW/OFF>",
                ]
                self.isHDRShooting = true    //HDR撮影
                
            case 4: //MOON_IMG
                self.propertyDictionary = [
                    "TAKEMODE":"<TAKEMODE/S>",
                    "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                    "SHUTTER":"<SHUTTER/640>",
                    "AE":"<AE/AE_PINPOINT>",
                    //"FOCUS_STILL":"<FOCUS_STILL/FOCUS_SAF>",
                    "RECVIEW":"<RECVIEW/OFF>",
                ]
                self.isAFPointCenter = true    //基本はAF位置がセンター
                
            case 5: //WATERFALL_IMG
                self.propertyDictionary = [
                    "TAKEMODE":"<TAKEMODE/S>",
                    "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                    "ISO":"<ISO/200>",
                    "SHUTTER":"<SHUTTER/1\">",
                    //"FOCUS_STILL":"<FOCUS_STILL/FOCUS_SAF>",
                    "RECVIEW":"<RECVIEW/OFF>",
                ]
            case 6: //FIREWORKS_IMG
                self.propertyDictionary = [
                    "TAKEMODE":"<TAKEMODE/M>",
                    "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                    "ISO":"<ISO/Low>",
                    "SHUTTER":"<SHUTTER/4\">",
                    "APERTURE":"<APERTURE/11>",
                    "WB":"<WB/MWB_LAMP>",
                    //"FOCUS_STILL":"<FOCUS_STILL/FOCUS_SAF>",
                    "RECVIEW":"<RECVIEW/OFF>",
                ]
            default:
                self.propertyDictionary = [
                    "TAKEMODE":"<TAKEMODE/iAuto>",
                    "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                    "RECVIEW":"<RECVIEW/OFF>",
                ]
                
            }
            println(self.propertyDictionary)
            result = camera.setCameraPropertyValues(self.propertyDictionary, error: nil)
        }
        if ((result) && (camera.connected)) {
            result = camera.startLiveView(nil)
        }
    }
    
    func disconnect(camera:OLYCamera) {
        if (camera.connected) {
            camera.disconnectWithPowerOff(false, error: nil)
        }
    }
    
    func takePicture(camera:OLYCamera) {
        let actionType :OLYCameraActionType = camera.actionType()
        let semaphore:dispatch_semaphore_t = dispatch_semaphore_create(0);
        
        if (self.isHDRShooting) {
            //HDR Shooting sequence call
            ShootingSequence().takePictureHDR(camera)
        } else if (actionType.value == OLYCameraActionTypeSingle.value) {
            if (self.isAFPointCenter) {
                camera.setAutoFocusPoint(CGPointMake(0.5, 0.5), error: nil)
            }
            ShootingSequence().takePictureSingle(camera)
            if (self.isAFPointCenter) {
                camera.clearAutoFocusPoint(nil)
            }
        } else if (actionType.value == OLYCameraActionTypeSequential.value) {
            //撮影可能枚数の上限を10枚とする(10fpsなので1秒間撮影)
            let option:Dictionary = [OLYCameraStartTakingPictureOptionLimitShootingsKey:10]
            camera.startTakingPicture(option, progressHandler: nil, completionHandler: {
                }, errorHandler: nil)
            NSThread.sleepForTimeInterval(1.2)
            camera.stopTakingPicture(nil, completionHandler: nil, errorHandler: nil)
        } else if (actionType.value == OLYCameraActionTypeMovie.value) {
            if (camera.recordingVideo) {
                if(!isClipsMovie) {
                    camera.stopRecordingVideo( { info in
                        dispatch_semaphore_signal(semaphore)
                        }, errorHandler: nil)
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                }
            } else {
                camera.startRecordingVideo(nil, completionHandler: {
                    dispatch_semaphore_signal(semaphore)
                    }, errorHandler: nil)
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            }
        }
    }

}

//
//  CameraKitWrapper.swift
//  AirRecipe
//
//  Created by Fuji on 2015/07/01.
//  Copyright (c) 2015年 FromF. All rights reserved.
//

//import Cocoa
import CoreLocation

class CameraKitWrapper: NSObject {
    //Clips Mode Flag
    var isClipsMovie : Bool = false
    //HDR Mode Flag
    var isHDRShooting : Bool = false
    //AF Point Center Flag
    var isAFPointCenter : Bool = false
    //GeoTag
    var nmea0183:NSMutableString = ""
    //CameraProperty
    var propertyDictionary = [
        "TAKEMODE":"<TAKEMODE/iAuto>",
        "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
    ]
    var enableBrightness:Bool = true
    var useExpRev:Bool = false
    var useToneControlMiddle:Bool = false
    var toneControlMiddleValue : NSInteger = 7
    let toneControlMiddleSettingList = [
        "<TONE_CONTROL_MIDDLE/-7>",
        "<TONE_CONTROL_MIDDLE/-6>",
        "<TONE_CONTROL_MIDDLE/-5>",
        "<TONE_CONTROL_MIDDLE/-4>",
        "<TONE_CONTROL_MIDDLE/-3>",
        "<TONE_CONTROL_MIDDLE/-2>",
        "<TONE_CONTROL_MIDDLE/-1>",
        "<TONE_CONTROL_MIDDLE/0>",
        "<TONE_CONTROL_MIDDLE/+1>",
        "<TONE_CONTROL_MIDDLE/+2>",
        "<TONE_CONTROL_MIDDLE/+3>",
        "<TONE_CONTROL_MIDDLE/+4>",
        "<TONE_CONTROL_MIDDLE/+5>",
        "<TONE_CONTROL_MIDDLE/+6>",
        "<TONE_CONTROL_MIDDLE/+7>",
    ]
    var expRevValue : NSInteger = 15
    let expRevSettingValueList = [
        "<EXPREV/-5.0>",
        "<EXPREV/-4.7>",
        "<EXPREV/-4.3>",
        "<EXPREV/-4.0>",
        "<EXPREV/-3.7>",
        "<EXPREV/-3.3>",
        "<EXPREV/-3.0>",
        "<EXPREV/-2.7>",
        "<EXPREV/-2.3>",
        "<EXPREV/-2.0>",
        "<EXPREV/-1.7>",
        "<EXPREV/-1.3>",
        "<EXPREV/-1.0>",
        "<EXPREV/-0.7>",
        "<EXPREV/-0.3>",
        "<EXPREV/0.0>",
        "<EXPREV/+0.3>",
        "<EXPREV/+0.7>",
        "<EXPREV/+1.0>",
        "<EXPREV/+1.3>",
        "<EXPREV/+1.7>",
        "<EXPREV/+2.0>",
        "<EXPREV/+2.3>",
        "<EXPREV/+2.7>",
        "<EXPREV/+3.0>",
        "<EXPREV/+3.3>",
        "<EXPREV/+3.7>",
        "<EXPREV/+4.0>",
        "<EXPREV/+4.3>",
        "<EXPREV/+4.7>",
        "<EXPREV/+5.0>",
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
            enableBrightness = true
            useExpRev = false
            useToneControlMiddle = true

            switch(index) {
            case 0: //SINGLE_IMG
                self.propertyDictionary = [
                    "TAKEMODE":"<TAKEMODE/P>",
                    "COLORTONE":"<COLORTONE/I_FINISH>",
                    "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                    "WB":"<WB/WB_AUTO>",
                    "TONE_CONTROL_LOW":"<TONE_CONTROL_LOW/0>",
                    "TONE_CONTROL_MIDDLE":toneControlMiddleSettingList[toneControlMiddleValue],
                    "TONE_CONTROL_HIGH":"<TONE_CONTROL_HIGH/0>",
                    "AUTO_WB_DENKYU_COLORED_LEAVING":"<AUTO_WB_DENKYU_COLORED_LEAVING/ON>",
                    "RECVIEW":"<RECVIEW/OFF>",
                ]
                
            case 1: //CONTINUOUS_IMG
                self.propertyDictionary = [
                    "TAKEMODE":"<TAKEMODE/P>",
                    "COLORTONE":"<COLORTONE/I_FINISH>",
                    "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_CONTINUE>",
                    "WB":"<WB/WB_AUTO>",
                    "TONE_CONTROL_LOW":"<TONE_CONTROL_LOW/0>",
                    "TONE_CONTROL_MIDDLE":toneControlMiddleSettingList[toneControlMiddleValue],
                    "TONE_CONTROL_HIGH":"<TONE_CONTROL_HIGH/0>",
                    "AUTO_WB_DENKYU_COLORED_LEAVING":"<AUTO_WB_DENKYU_COLORED_LEAVING/ON>",
                    "RECVIEW":"<RECVIEW/OFF>",
                ]
                
            case 2: //MOVIE_IMG
                useExpRev = true
                useToneControlMiddle = false
                self.propertyDictionary = [
                    "TAKEMODE":"<TAKEMODE/movie>",
                    "QUALITY_MOVIE":"<QUALITY_MOVIE/QUALITY_MOVIE_SHORT_MOVIE>",
                    "FULL_TIME_AF":"<FULL_TIME_AF/ON>",
                    "EXPREV":expRevSettingValueList[expRevValue],
                ]
                self.isClipsMovie = true    //Clips動画
                
            case 3: //HDR_IMG
                self.propertyDictionary = [
                    "TAKEMODE":"<TAKEMODE/A>",
                    "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                    "APERTURE":"<APERTURE/8.0>",
                    //"RAW":"<RAW/ON>",
                    "RECVIEW":"<RECVIEW/OFF>",
                    "WB":"<WB/WB_AUTO>",
                    "TONE_CONTROL_LOW":"<TONE_CONTROL_LOW/0>",
                    "TONE_CONTROL_MIDDLE":toneControlMiddleSettingList[toneControlMiddleValue],
                    "TONE_CONTROL_HIGH":"<TONE_CONTROL_HIGH/0>",
                    "AUTO_WB_DENKYU_COLORED_LEAVING":"<AUTO_WB_DENKYU_COLORED_LEAVING/ON>",
                ]
                self.isHDRShooting = true    //HDR撮影
                
            case 4: //MOON_IMG
                enableBrightness = false
                self.propertyDictionary = [
                    "TAKEMODE":"<TAKEMODE/M>",
                    "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                    "RECVIEW":"<RECVIEW/OFF>",
                ]
                //月齢に応じてシャッタースピード,絞り,ISOを決定する
                let monthOld:Double = getMonthOld()
                
                if (monthOld >= 13.6) && (monthOld <= 16.0) { //満月14.8
                    propertyDictionary["ISO"] = "<ISO/800>"
                    propertyDictionary["SHUTTER"] = "<SHUTTER/1000>"
                    propertyDictionary["APERTURE"] = "<APERTURE/8.0>"
                } else if ((monthOld >= 11.1) && (monthOld <= 13.5)) || ((monthOld >= 16.1) && (monthOld <= 18.5)) { //12.3,17.3
                    propertyDictionary["ISO"] = "<ISO/800>"
                    propertyDictionary["SHUTTER"] = "<SHUTTER/500>"
                    propertyDictionary["APERTURE"] = "<APERTURE/8.0>"
                } else if ((monthOld >= 8.7) && (monthOld <= 11.0)) || ((monthOld >= 18.6) && (monthOld <= 21)) { //9.9,19.8
                    propertyDictionary["ISO"] = "<ISO/800>"
                    propertyDictionary["SHUTTER"] = "<SHUTTER/500>"
                    propertyDictionary["APERTURE"] = "<APERTURE/6.3>"
                } else if ((monthOld >= 6.2) && (monthOld <= 8.6)) || ((monthOld >= 21.1) && (monthOld <= 23.5)) { //半月7.4,22.3
                    propertyDictionary["ISO"] = "<ISO/800>"
                    propertyDictionary["SHUTTER"] = "<SHUTTER/250>"
                    propertyDictionary["APERTURE"] = "<APERTURE/6.3>"
                } else if ((monthOld >= 3.7) && (monthOld <= 6.1)) || ((monthOld >= 23.6) && (monthOld <= 26.0)) { //4.9,24.8
                    propertyDictionary["ISO"] = "<ISO/1250>"
                    propertyDictionary["SHUTTER"] = "<SHUTTER/250>"
                    propertyDictionary["APERTURE"] = "<APERTURE/6.3>"
                } else if ((monthOld >= 0) && (monthOld <= 3.6)) || ((monthOld >= 26.1) && (monthOld <= 30.0)) { //三日月2.5,27.3
                    propertyDictionary["ISO"] = "<ISO/1600>"
                    propertyDictionary["SHUTTER"] = "<SHUTTER/250>"
                    propertyDictionary["APERTURE"] = "<APERTURE/6.3>"
                }
                self.isAFPointCenter = true    //基本はAF位置がセンター
            case 5: //WATERFALL_IMG
                enableBrightness = false
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
                    "TONE_CONTROL_LOW":"<TONE_CONTROL_LOW/0>",
                    "TONE_CONTROL_MIDDLE":toneControlMiddleSettingList[toneControlMiddleValue],
                    "TONE_CONTROL_HIGH":"<TONE_CONTROL_HIGH/0>",
                ]
            default:
                self.propertyDictionary = [
                    "TAKEMODE":"<TAKEMODE/iAuto>",
                    "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                    "RECVIEW":"<RECVIEW/OFF>",
                ]
                
            }
            //println(self.propertyDictionary)
            result = camera.setCameraPropertyValues(self.propertyDictionary, error: nil)
        }
        if ((result) && (camera.connected)) {
            result = camera.startLiveView(nil)
        }
        if ((result) && (camera.connected)) {
            if (nmea0183 != "") {
                result = camera.setGeolocation(nmea0183 as String, error: nil)
            }
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
            camera.lockAutoExposure(nil)
            camera.lockAutoFocus( { info -> Void in
                    dispatch_semaphore_signal(semaphore)
                    println("Comp")
                }, errorHandler: { error -> Void in
                    dispatch_semaphore_signal(semaphore)
                    println("Error")
                })
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            for var i = 0 ; i < 3 ; i++ {
                switch i {
                    case 0:
                        camera.setCameraPropertyValue("EXPREV", value: "<EXPREV/+2.0>", error: nil)
                    case 1:
                        camera.setCameraPropertyValue("EXPREV", value: "<EXPREV/0.0>", error: nil)
                    case 2:
                        camera.setCameraPropertyValue("EXPREV", value: "<EXPREV/-2.0>", error: nil)
                    default:
                        camera.setCameraPropertyValue("EXPREV", value: "<EXPREV/+0.0>", error: nil)
                }
                camera.takePicture(nil, progressHandler: nil, completionHandler:{info -> Void in
                        dispatch_semaphore_signal(semaphore)
                        println("Comp")
                    }, errorHandler: {error -> Void in
                        dispatch_semaphore_signal(semaphore)
                        println("Error")
                    })
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                while camera.mediaBusy {
                    println("media busy...")
                    NSThread.sleepForTimeInterval(0.5)
                }
            }
            camera.setCameraPropertyValue("EXPREV", value: "<EXPREV/0.0>", error: nil)
            camera.unlockAutoFocus(nil)
            camera.unlockAutoExposure(nil)
        } else if (actionType.value == OLYCameraActionTypeSingle.value) {
            if (self.isAFPointCenter) {
                camera.setAutoFocusPoint(CGPointMake(0.5, 0.5), error: nil)
            }
            camera.takePicture(nil, progressHandler: nil, completionHandler:{info -> Void in
                dispatch_semaphore_signal(semaphore)
                println("Comp")
                }, errorHandler: {error -> Void in
                    dispatch_semaphore_signal(semaphore)
                    println("Error")
            })
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            if (self.isAFPointCenter) {
                camera.clearAutoFocusPoint(nil)
            }
        } else if (actionType.value == OLYCameraActionTypeSequential.value) {
            //撮影可能枚数の上限を10枚とする(10fpsなので1秒間撮影)
            let option:Dictionary = [OLYCameraStartTakingPictureOptionLimitShootingsKey:10]
            camera.startTakingPicture(option, progressHandler: nil, completionHandler: {
                dispatch_semaphore_signal(semaphore)
                println("Comp")
                }, errorHandler: {error -> Void in
                    dispatch_semaphore_signal(semaphore)
                    println("Error")
            })
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            NSThread.sleepForTimeInterval(1.2)
            camera.stopTakingPicture(nil, completionHandler: nil, errorHandler: nil)
        } else if (actionType.value == OLYCameraActionTypeMovie.value) {
            if (camera.recordingVideo) {
                if(!isClipsMovie) {
                    camera.stopRecordingVideo( { info in
                        dispatch_semaphore_signal(semaphore)
                        println("Comp")
                    }, errorHandler: {error -> Void in
                        dispatch_semaphore_signal(semaphore)
                        println("Error")
                    })
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                }
            } else {
                camera.startRecordingVideo(nil, completionHandler: {
                    dispatch_semaphore_signal(semaphore)
                    println("Comp")
                }, errorHandler: {error -> Void in
                    dispatch_semaphore_signal(semaphore)
                    println("Error")
                })
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                if(isClipsMovie) {
                    //Clipsの場合は動画撮影完了するまで待つ
                    while(camera.recordingVideo) {
                        NSThread.sleepForTimeInterval(0.5)
                    }
                }
            }
        }
    }
    
    func setGeoLocation(camera:OLYCamera , location:CLLocation) {
        // 10進数の緯度経度を60進数の緯度経度に変換
        let latitude:CLLocationDegrees = convertCLLocationDegreesToNmea(location.coordinate.latitude)
        let longitude:CLLocationDegrees = convertCLLocationDegreesToNmea(location.coordinate.longitude)
        
        // GPGGAレコード
        var nmea0183GPGGA:NSMutableString = ""
        var nmea0183GPGGATimestampFormatter:NSDateFormatter = NSDateFormatter()
        nmea0183GPGGATimestampFormatter.timeZone = NSTimeZone(name: "UTC")
        nmea0183GPGGATimestampFormatter.dateFormat = "HHmmss.SSS"
        
        nmea0183GPGGA.appendString("GPGGA,")
        nmea0183GPGGA.appendFormat("%@,", nmea0183GPGGATimestampFormatter.stringFromDate(location.timestamp))
        nmea0183GPGGA.appendFormat("%08.4f,", latitude)         // 緯度
        if latitude > 0.0 {                                     // 北緯、南緯
            nmea0183GPGGA.appendString("N,")
        } else {
            nmea0183GPGGA.appendString("S,")
        }
        nmea0183GPGGA.appendFormat("%08.4f,", longitude)        // 経度
        if longitude > 0.0 {                                    // 東経、西経
            nmea0183GPGGA.appendString("E,")
        } else {
            nmea0183GPGGA.appendString("W,")
        }
        nmea0183GPGGA.appendString("1,")                        //位置特定品質: 単独測位
        nmea0183GPGGA.appendString("08,")                       //受信衛星数: 8?
        nmea0183GPGGA.appendString("1.0,")                      //水平精度低下率: 1.0?
        nmea0183GPGGA.appendFormat("%1.1f,", location.altitude) // アンテナの海抜高さ
        nmea0183GPGGA.appendString("M,")                        // アンテナの海抜高さ単位: メートル
        nmea0183GPGGA.appendFormat("%1.1f,", location.altitude) // ジオイド高さ
        nmea0183GPGGA.appendString("M,")                        // ジオイド高さ: メートル
        nmea0183GPGGA.appendString(",")                         // DGPSデータの寿命: 不使用
        nmea0183GPGGA.appendString(",")                         // 差動基準地点ID: 不使用
        
        var nmea0183GPGGAChecksum:unichar = 0
        for var index:NSInteger = 0 ; index < nmea0183GPGGA.length ; index++ {
            nmea0183GPGGAChecksum ^= nmea0183GPGGA.characterAtIndex(index)
        }
        nmea0183GPGGAChecksum &= 0x0ff
        
        
        nmea0183GPGGA.insertString("$", atIndex: 0)
        nmea0183GPGGA.appendString("*")
        nmea0183GPGGA.appendFormat("%02lX",nmea0183GPGGAChecksum)     // チェックサム

        // GPRMCレコード
        var nmea0183GPRMC:NSMutableString = ""
        var nmea0183GPRMCTimestampFormatter:NSDateFormatter = NSDateFormatter()
        nmea0183GPRMCTimestampFormatter.timeZone = NSTimeZone(name: "UTC")
        nmea0183GPRMCTimestampFormatter.dateFormat = "HHmmss.SSS"
        var nmea0183GPRMCDateFormatter:NSDateFormatter = NSDateFormatter()
        nmea0183GPRMCDateFormatter.timeZone = NSTimeZone(name: "UTC")
        nmea0183GPRMCDateFormatter.dateFormat = "ddMMyy"
        
        nmea0183GPRMC.appendString("GPRMC,")
        nmea0183GPRMC.appendFormat("%@,",nmea0183GPRMCTimestampFormatter.stringFromDate(location.timestamp))
        
        nmea0183GPRMC.appendString("A,")                        // ステータス: 有効
        nmea0183GPRMC.appendFormat("%08.4f,", latitude)         // 緯度
        if latitude > 0.0 {                                     // 北緯、南緯
            nmea0183GPRMC.appendString("N,")
        } else {
            nmea0183GPRMC.appendString("S,")
        }
        nmea0183GPRMC.appendFormat("%08.4f,", longitude)        // 経度
        if longitude > 0.0 {                                    // 東経、西経
            nmea0183GPRMC.appendString("E,")
        } else {
            nmea0183GPRMC.appendString("W,")
        }
        var speed : Double = 0.0
        var course : Double = 0.0
        if location.course > 0.0 {
            speed = location.speed * 3600.0 / 1000.0 * 0.54
            course = location.course
        }
        nmea0183GPRMC.appendFormat("%04.1f,",speed)             // 移動速度(ノット毎時)
        nmea0183GPRMC.appendFormat("%04.1f,",course)            // 移動方向
        nmea0183GPRMC.appendFormat("%@",nmea0183GPRMCDateFormatter.stringFromDate(location.timestamp))  // 測位日付
        nmea0183GPRMC.appendString(",")                         // 地磁気の偏角: 不使用
        nmea0183GPRMC.appendString(",")                         // 地磁気の偏角の方向: 不使用
        nmea0183GPRMC.appendString("A")                         // モード: 単独測位
        
        var nmea0183GPRMCChecksum:unichar = 0
        for var index:NSInteger = 0 ; index < nmea0183GPRMC.length ; index++ {
            nmea0183GPRMCChecksum ^= nmea0183GPRMC.characterAtIndex(index)
        }
        nmea0183GPRMCChecksum &= 0x0ff
        
        
        nmea0183GPRMC.insertString("$", atIndex: 0)
        nmea0183GPRMC.appendString("*")
        nmea0183GPRMC.appendFormat("%02lX",nmea0183GPRMCChecksum)     // チェックサム
        
        // カメラに位置情報を設定します。
        var nmea0183New:NSMutableString = ""
        nmea0183New.appendFormat("%@\n%@\n", nmea0183GPGGA, nmea0183GPRMC)
        
        println(nmea0183New)
        if (nmea0183 == nmea0183New) {
            println("Same Location")
        } else {
            nmea0183 = nmea0183New
            if (camera.connected) {
                camera.setGeolocation(self.nmea0183 as String, error: nil)
            } else {
                println("Not Connected")
            }
        }
    }

    private func convertCLLocationDegreesToNmea(degrees:CLLocationDegrees) ->Double {
        var degreeSign:Double = 0
        
        if degrees > 0.0 {
            degreeSign = 1
        } else if degrees < 0.0 {
            degreeSign = -1
        } else {
            degreeSign = 0
        }
        
        let degree:Double = abs(degrees)
        let degreeDecimal:Double = floor(degree)
        let degreeFraction:Double = degree - degreeDecimal
        let minutes = degreeFraction * 60.0
        let nmea = degreeSign * (degreeDecimal * 100.0 + minutes)
        
        return nmea
    }
    
    func getMonthOld() -> Double {
        let date = NSDate()
        let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)
        var comps:NSDateComponents = calendar!.components(NSCalendarUnit.CalendarUnitYear | NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitDay, fromDate: date)
        let year:Double = Double(comps.year)
        let month:Double = Double(comps.month)
        let day:Double = Double(comps.day)
        //(((YYYY-2009) %19)×11+MM+DD) %30
        var monthOld:Double = (((year - 2009) % 19.0) * 11.0 + month + day) % 30.0
        if month <= 2 {
            // 1月と2月の月齢については、上記計算値に 2 を加える
            monthOld += 2.0
        }
        if monthOld > 30.0 {
            // 30超えると想定外になるため30にクリップする
            monthOld = 30.0
        }
        //println("monthOld:\(monthOld)")
        
        return monthOld
    }
    
    func setToneControlMiddle(camera:OLYCamera , value : NSInteger) -> Bool {
        let result = camera.setCameraPropertyValue("TONE_CONTROL_MIDDLE", value: toneControlMiddleSettingList[value], error: nil)
        return result
    }
    func setExpRev(camera:OLYCamera , value : NSInteger) -> Bool {
        let result = camera.setCameraPropertyValue("EXPREV", value: expRevSettingValueList[value], error: nil)
        return result
    }
}

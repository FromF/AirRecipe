//
//  CameraKitWrapper.swift
//  AirRecipe
//
//  Created by 藤　治仁 on 2018/02/22.
//  Copyright © 2018年 Personal. All rights reserved.
//

import UIKit

/// OLYCameraKitラッピング層
/// Objective-Cへのブリッジおよび機能実現するシーケンス化行なっている
class CameraKitWrapper: NSObject {
    /// シングルトン
    static let shared = CameraKitWrapper()
    
    /// OLYCameraKitインスタンス
    let cameraKit = OLYCamera()
    
    /// デジタルズーム倍率
    var digitalZoomCurrent:Float = 1.0
    
    // MARK: - 接続＆切断
    /// OLYMPUS Air A01と接続
    ///
    /// - Parameter cameraKitProperty: 撮影モード用のカメラプロパティー設定
    /// - Returns: 成功/失敗
    func connectOPC(cameraKitProperty:[String:String]?) -> Bool {
        var result = true
        
        if result && !cameraKit.connected {
            do {
                try cameraKit.connect(OLYCameraConnectionTypeWiFi)
                result = true
            } catch let error {
                errorLog("\(error)")
                result = false
            }
        }
        
        if result && cameraKit.connected {
            //ライブビュー転送が自動で開始しないようにする
            cameraKit.autoStartLiveView = false
            do {
                try cameraKit.changeRunMode(OLYCameraRunModeRecording)
                result = true
            } catch let error {
                errorLog("\(error)")
                result = false
            }
        }
        if result && cameraKit.connected {
            if let property = cameraKitProperty {
                do {
                    try cameraKit.setCameraPropertyValues(property)
                    result = true
                } catch let error {
                    errorLog("\(error)")
                    result = false
                }
            }
        }
        if result && cameraKit.connected {
            do {
                try cameraKit.startLiveView()
                result = true
            } catch let error {
                errorLog("\(error)")
                result = false
            }
        }
        //デジタルズーム倍率を初期化
        digitalZoomCurrent = 1.0
        return result
    }
    
    /// OLYMPUS Air A01との通信を切断する
    ///
    /// - Parameter powerOff: パワーオフするか否か
    func disconnect(powerOff:Bool) {
        if cameraKit.connected {
            do {
                try cameraKit.disconnect(withPowerOff: powerOff)
            } catch let error {
                errorLog("\(error)")
            }
        }
    }

    /// 接続試験を行う
    ///
    /// - Parameter timeOut: タイムアウト時間
    /// - Returns: 成否
    func waitConnectWiFi(timeOut:Int) -> Bool {
        var result = false
        
        for _ in 0..<(timeOut * 2) {
            do {
                try cameraKit.canConnect(OLYCameraConnectionTypeWiFi, timeout: 0.5)
                result = true
            } catch let error {
                errorLog("\(error)")
            }
            if result {
                break
            }
        }
        
        return result
    }

    // MARK: - 設定値
    /// カメラプロパティー取得
    ///
    /// - Parameter name: 取得対象プロパティー名
    /// - Returns: プロパティー値
    func getPropertyValue(name:String) -> String? {
        var result:String?
        if cameraKit.connected {
            do {
                result = try cameraKit.cameraPropertyValue(name)
            } catch let error {
                errorLog("\(error)")
            }
        }
        
        return result
    }
    
    /// カメラプロパティー設定
    ///
    /// - Parameters:
    ///   - name: 設定対象プロパティー名
    ///   - value: プロパティー値
    func setPropertyValue(name:String , value:String) {
        if cameraKit.connected {
            do {
                try cameraKit.setCameraPropertyValue(name, value: "<\(name)/\(value)>")
            } catch let error {
                errorLog("\(error)")
            }
        }
    }
    
    // MARK: - カメラステータス
    /// メディア残量取得
    ///
    /// - Returns: メディア残量
    func getMediaRemain() -> String? {
        var result:String?
        if cameraKit.connected {
            if cameraKit.actionType() == OLYCameraActionTypeMovie {
                if !cameraKit.recordingVideo {
                    let second = Int(cameraKit.remainingVideoCapacity) % 60
                    let hour = Int(cameraKit.remainingVideoCapacity) / (60*60)
                    let miniute = (Int(cameraKit.remainingVideoCapacity) - (hour * 60 * 60) - second) / 60
                    result = String(format: "%02d:%02d:%02d",hour,miniute,second)
                }
            } else {
                result = "\(cameraKit.remainingImageCapacity)"
            }
        }
        return result
    }

    // MARK: - 撮影
    /// 通常撮影(静止画)
    ///
    /// - Parameter completionHandler: 実行完了通知
    /// - Returns: 実行開始有無
    func takeNormal(completionHandler: @escaping (_ result:Bool) -> Void) -> Bool {
        var result = true
        
        if cameraKit.connected && (cameraKit.actionType() == OLYCameraActionTypeSingle || cameraKit.actionType() == OLYCameraActionTypeSequential) {
            var option:[String:Any]?
            do {
                try cameraKit.setAutoFocus(CGPoint(x: 0.5, y: 0.5))
            } catch let error {
                errorLog("\(error)")
                result = false
            }
            
            if cameraKit.actionType() == OLYCameraActionTypeSequential {
                option = [OLYCameraStartTakingPictureOptionLimitShootingsKey:10]
                cameraKit.startTakingPicture(option, progressHandler: nil, completionHandler: {
                    do {
                        try self.cameraKit.clearAutoFocusPoint()
                    } catch let error {
                        errorLog("\(error)")
                    }
                    if self.cameraKit.actionType() == OLYCameraActionTypeSequential {
                        Thread.sleep(forTimeInterval: 1.2)
                        self.cameraKit.stopTakingPicture(nil, completionHandler: nil, errorHandler: nil)
                    }
                    completionHandler(true)
                }, errorHandler: { (error) in
                    completionHandler(false)
                })
            } else {
                cameraKit.takePicture(nil, progressHandler: nil, completionHandler: { (info) in
                    do {
                        try self.cameraKit.clearAutoFocusPoint()
                    } catch let error {
                        errorLog("\(error)")
                    }
                    completionHandler(true)
                }, errorHandler: { (error) in
                    completionHandler(false)
                })
            }
        }
        return result
    }
    
    /// HDR撮影(静止画)
    ///
    /// - Returns: 実行開始有無
    func takeHDRShooting() -> Bool {
        //セマフォ作成
        let semaphore = DispatchSemaphore(value: 0)
        var result = true
        if cameraKit.connected && cameraKit.actionType() == OLYCameraActionTypeSingle {
            if result {
                do {
                    try cameraKit.lockAutoExposure()
                } catch let error {
                    errorLog("\(error)")
                    result = false
                }
            }
            if result {
                cameraKit.lockAutoFocus({ (info) in
                    //セマフォシグナル
                    semaphore.signal()
                }, errorHandler: { (error) in
                    result = false
                    //セマフォシグナル
                    semaphore.signal()
                })
                //セマフォ待ち
                _ = semaphore.wait(timeout:.distantFuture)
            }
            
            for exprev in ["+2.0","0.0","-2.0"] {
                if result {
                    do {
                        try cameraKit.setCameraPropertyValue("EXPREV", value: "<EXPREV/\(exprev)>")
                    } catch let error {
                        errorLog("\(error)")
                        result = false
                    }
                }
                if result {
                    cameraKit.takePicture(nil, progressHandler: nil, completionHandler: { (info) in
                        //セマフォシグナル
                        semaphore.signal()
                    }, errorHandler: { (error) in
                        result = false
                        //セマフォシグナル
                        semaphore.signal()
                    })
                    //セマフォ待ち
                    _ = semaphore.wait(timeout:.distantFuture)
                }
                if result {
                    repeat {
                        debugLog("media busy...\(cameraKit.mediaBusy)")
                        Thread.sleep(forTimeInterval: 0.5)
                    } while cameraKit.mediaBusy
                }
            }
            if result {
                do {
                    try cameraKit.setCameraPropertyValue("EXPREV", value: "<EXPREV/0.0>")
                } catch let error {
                    errorLog("\(error)")
                    result = false
                }
            }
            if result {
                do {
                    try cameraKit.unlockAutoFocus()
                } catch let error {
                    errorLog("\(error)")
                    result = false
                }
            }
            if result {
                do {
                    try cameraKit.unlockAutoExposure()
                } catch let error {
                    errorLog("\(error)")
                    result = false
                }
            }
        }
        
        return result
    }
    
    /// 動画撮影
    ///
    /// - Parameters:
    ///   - isClips: クリップス撮影
    ///   - completionHandler: 実行完了通知
    /// - Returns: 実行開始有無
    func takeMovie(isClips:Bool , completionHandler: @escaping (_ result:Bool) -> Void) {
        if cameraKit.connected && cameraKit.actionType() == OLYCameraActionTypeMovie {
            if cameraKit.recordingVideo {
                cameraKit.stopRecordingVideo({ (info) in
                    completionHandler(true)
                }, errorHandler: { (error) in
                    completionHandler(false)
                })
            } else {
                cameraKit.startRecordingVideo(nil, completionHandler: {
                    if isClips {
                        repeat {
                            debugLog("recording...\(self.cameraKit.recordingVideo)")
                            Thread.sleep(forTimeInterval: 0.5)
                        } while self.cameraKit.recordingVideo
                    }
                    completionHandler(true)
                }, errorHandler: { (error) in
                    completionHandler(false)
                })
            }
        }
    }
    
    // MARK: - AF関連
    /// タッチAF
    ///
    /// - Parameter point: AFポイント
    /// - Returns: 実行可否
    func setAfPoint(point:CGPoint) -> Bool {
        var result = true
        
        if cameraKit.connected {
            if try! cameraKit.cameraPropertyValue("FOCUS_STILL") != "<FOCUS_STILL/FOCUS_MF>" {
                if result {
                    do {
                        try cameraKit.unlockAutoFocus()
                    } catch let error {
                        errorLog("\(error)")
                        result = false
                    }
                }
                if result {
                    do {
                        try cameraKit.setAutoFocus(point)
                    } catch let error {
                        errorLog("\(error)")
                        result = false
                    }
                }
                if result {
                    //セマフォ作成
                    let semaphore = DispatchSemaphore(value: 0)
                    cameraKit.lockAutoFocus({ (info) in
                        if let resultInfo = info as? [String:String] , let afResult = resultInfo[OLYCameraTakingPictureProgressInfoFocusResultKey] {
                             if afResult != "ok" {
                                do {
                                    try self.cameraKit.unlockAutoFocus()
                                } catch let error {
                                    errorLog("\(error)")
                                    result = false
                                }
                            }
                        }
                        //セマフォシグナル
                        semaphore.signal()
                    }, errorHandler: { (error) in
                        result = false
                        //セマフォシグナル
                        semaphore.signal()
                    })
                    //セマフォ待ち
                    _ = semaphore.wait(timeout:.distantFuture)
                }
            }
        }
        
        return result
    }
    // MARK: - デジタルテレコン
    /// デジタルテレコン倍率変更
    /// - digitalZoomCurrentに現在の倍率が格納されている
    func changeDigitalTelecon() {
        var result = true
        let digitalZoomArray:[Float] = [1.0 , 2.0 , 3.0]
        var digitalZoom:Float = 1.0
        for index in 0..<(digitalZoomArray.count - 1) {
            if digitalZoomCurrent == digitalZoomArray[index] {
                digitalZoom = digitalZoomArray[index + 1]
            }
        }
        
        do {
            try self.cameraKit.changeDigitalZoomScale(digitalZoom)
        } catch let error {
            errorLog("\(error)")
            result = false
        }
        if result {
            digitalZoomCurrent = digitalZoom
        }
    }

}

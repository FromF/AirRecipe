//
//  LiveViewController.swift
//  AirRecipe
//
//  Created by Fuji on 2015/07/01.
//  Copyright (c) 2015年 FromF. All rights reserved.
//

import UIKit
import CoreLocation
import MediaPlayer
import AudioToolbox

class LiveViewController: UIViewController ,CLLocationManagerDelegate ,OLYCameraLiveViewDelegate , OLYCameraConnectionDelegate , OLYCameraPropertyDelegate , OLYCameraRecordingSupportsDelegate , MBProgressHUDDelegate {
    
    //
    @IBOutlet weak var liveViewImage: UIImageView!
    @IBOutlet weak var shutterButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var batteryLevelImage: UIImageView!
    @IBOutlet weak var mediaRemainLabel: UILabel!
    @IBOutlet weak var digitalTeleconButton: UIButton!
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var brightnessEnableButton: UIButton!
    
    //
    //AppDelegate instance
    var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    //CameraKitWrapper
    let cameraWrapper = CameraKitWrapper()
    //MBProgressHUD
    var hud: MBProgressHUD!
    //CoreLocation Serivce
    var locationManager = CLLocationManager()
    //BatteryLevelMeter
    let batteryIconList = [
        "<BATTERY_LEVEL/UNKNOWN>": "lv_battery_01",
        "<BATTERY_LEVEL/CHARGE>": "lv_battery_01",
        "<BATTERY_LEVEL/EMPTY>": "lv_battery_01",
        "<BATTERY_LEVEL/WARNING>": "lv_battery_01",
        "<BATTERY_LEVEL/LOW>": "lv_battery_02",
        "<BATTERY_LEVEL/FULL>": "lv_battery_03",
        "<BATTERY_LEVEL/EMPTY_AC>": "lv_battery_01",
        "<BATTERY_LEVEL/SUPPLY_WARNING>": "lv_battery_01",
        "<BATTERY_LEVEL/SUPPLY_LOW>": "lv_battery_02",
        "<BATTERY_LEVEL/SUPPLY_FULL>": "lv_battery_03",
    ]
    //brightnessSliderEnable
    var brightnessSliderEnable:Bool = false
    var brightnessSliderDisableTimer:NSTimer!
    //DigitalZoomList
    let digitalZoomList:[Float] = [ 1.0 , 2.0 , 3.0]
    var digitalZoomValue:Float = 1.0
    //Debug Mode
    let debugMode = false
    let memoryrightness = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //スリープ禁止
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        //必要な通知周りを登録
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "NotificationApplicationBackground:", name: UIApplicationDidEnterBackgroundNotification , object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "NotificationWatchAppStared:", name: appDelegate.NotificationWatchAppStared as String, object: nil)

        //CameraKitのインスタンス及び必要delegateを設定
        var camera = AppDelegate.sharedCamera
        camera.connectionDelegate = self
        camera.liveViewDelegate = self
        camera.recordingSupportsDelegate = self
        camera.cameraPropertyDelegate = self
        camera.addObserver(self, forKeyPath: "remainingImageCapacity", options: nil, context: nil)
        
        //トーンコントロール値取得
        if memoryrightness {
            cameraWrapper.toneControlMiddleValue = appDelegate.defaults.objectForKey(appDelegate.ToneControlMiddle) as! NSInteger
            cameraWrapper.expRevValue = appDelegate.defaults.objectForKey(appDelegate.ExpRev) as! NSInteger
        }
        
        //明るさボタンの初期化
        brightnessSliderEnable = false
        updatebrightnessEnableButton()
        
        //レックビュー有無
        cameraWrapper.isRecview = appDelegate.defaults.objectForKey(appDelegate.isPostInstagram) as! Bool
        
        if !debugMode {
            //接続処理完了まではシャッターボタンは非表示にして動画時の表示変化が違和感を減らす
            self.UpdateUIattribute(false, hidden: true)
            showHud(NSLocalizedString("CONNECTING",comment: ""))
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                let currentPage = self.appDelegate.defaults.objectForKey(self.appDelegate.CatalogSelectNumber) as! NSInteger
                self.cameraWrapper.connectOPC(currentPage, camera: camera)
                camera.changeLiveViewSize(OLYCameraLiveViewSizeVGA, error: nil)
                dispatch_async(dispatch_get_main_queue(), {
                    if camera.connected {
                        if self.cameraWrapper.useToneControlMiddle {
                            self.brightnessSlider.value = Float(self.cameraWrapper.toneControlMiddleValue)
                            self.brightnessSlider.minimumValue = 0
                            self.brightnessSlider.maximumValue = 14
                        } else {
                            let actionType :OLYCameraActionType = camera.actionType()
                            if (actionType.value == OLYCameraActionTypeMovie.value) {
                                self.brightnessSlider.minimumValue = 6
                                self.brightnessSlider.maximumValue = 24
                            } else {
                                self.brightnessSlider.minimumValue = 0
                                self.brightnessSlider.maximumValue = 30
                            }
                            self.brightnessSlider.value = Float(self.cameraWrapper.expRevValue)
                        }

                        if camera.actionType().value == OLYCameraActionTypeMovie.value {
                            //動画撮影モード時はRECと表示する
                            self.shutterButton.setImage(UIImage(named: "rp_shutter_btn_video"), forState: UIControlState.Normal)
                        }
                        self.hideHud(NSLocalizedString("CONNECTCOMPLETE",comment: "") , time:0.1)
                    } else {
                        self.hideHud(NSLocalizedString("CONNECTFAIL",comment: "") , time:1.0)
                    }
                })
            })
        } else {
            mediaRemainLabel.text = "999"
            liveViewImage.image = UIImage(named: "sample_through.jpg")
            UpdateUIattribute(true,hidden: false)
        }
        
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //リモコン開始
        startRemoteControl()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        //スリープ許可
        UIApplication.sharedApplication().idleTimerDisabled = false
        
        //AIRとの切断処理
        var camera = AppDelegate.sharedCamera
        if camera.connected {
            cameraWrapper.disconnect(camera)
        }
        camera.removeObserver(self, forKeyPath: "remainingImageCapacity")
        
        //CoreLocation Serivce
        locationManager.stopUpdatingLocation()
        
        //リモコン終了
        endRemoteControl()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Rotate Support
    //サポートするデバイスの向きを指定する
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.All.rawValue)
    }
    //指定方向に自動的に変更するか？
    override func shouldAutorotate() -> Bool{
        return true
    }
    
    // MARK: - Button
    @IBAction func shutterButtonAction(sender: AnyObject) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            dispatch_async(dispatch_get_main_queue(), {
                self.UpdateUIattribute(false, hidden: false)
            })
            var camera = AppDelegate.sharedCamera
            
            self.cameraWrapper.takePicture(camera)
            
            dispatch_async(dispatch_get_main_queue(), {
                self.UpdateUIattribute(true, hidden: false)
            })
            NSThread.sleepForTimeInterval(0.5)
            self.updateCameraMediaRemain()
        })
    }
    
    @IBAction func disconnectButtonAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func digitalTeleconButtonAction(sender: AnyObject) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            var camera = AppDelegate.sharedCamera
            if camera.connected {
                dispatch_async(dispatch_get_main_queue(), {
                    self.UpdateUIattribute(false, hidden: false)
                })
                let digitalzoomrange = camera.digitalZoomScaleRange(nil)
                for var i = 0 ; i < self.digitalZoomList.count ; i++ {
                    if self.digitalZoomValue == self.digitalZoomList[i]  {
                        if i == (self.digitalZoomList.count - 1) {
                            self.digitalZoomValue = self.digitalZoomList[0]
                        } else {
                            self.digitalZoomValue = self.digitalZoomList[i+1]
                        }
                        break
                    }
                }
                if (digitalzoomrange[OLYCameraDigitalZoomScaleRangeMinimumKey]?.floatValue <= self.digitalZoomValue) ||
                    (digitalzoomrange[OLYCameraDigitalZoomScaleRangeMaximumKey]?.floatValue >= self.digitalZoomValue) {
                        camera.changeDigitalZoomScale(self.digitalZoomValue, error: nil)
                        if self.digitalZoomValue == 2.0 {
                            self.digitalTeleconButton.setImage(UIImage(named: "ar_icn_dtelecon_x2"), forState: UIControlState.Normal)
                            self.digitalTeleconButton.setImage(UIImage(named: "ar_icn_dtelecon_x2_pushed"), forState: UIControlState.Highlighted)
                        } else if self.digitalZoomValue == 3.0 {
                            self.digitalTeleconButton.setImage(UIImage(named: "ar_icn_dtelecon_x3"), forState: UIControlState.Normal)
                            self.digitalTeleconButton.setImage(UIImage(named: "ar_icn_dtelecon_x3_pushed"), forState: UIControlState.Highlighted)
                        } else  {
                            self.digitalTeleconButton.setImage(UIImage(named: "ar_icn_dtelecon_x1"), forState: UIControlState.Normal)
                            self.digitalTeleconButton.setImage(UIImage(named: "ar_icn_dtelecon_x1_pushed"), forState: UIControlState.Highlighted)
                        }
                }
                dispatch_async(dispatch_get_main_queue(), {
                    self.UpdateUIattribute(true, hidden: false)
                })
            }
        })
    }
    @IBAction func brightnessSliderAction(sender: AnyObject) {
        let slider : UISlider = sender as! UISlider
        //四捨五入
        brightnessSlider.value = roundf(slider.value)
        //整数型に変換
        let value:NSInteger = NSInteger(brightnessSlider.value)
        let camera = AppDelegate.sharedCamera
        if cameraWrapper.useToneControlMiddle {
            brightnessSlider.value = Float(value)
            cameraWrapper.setToneControlMiddle(camera, value: value)
            appDelegate.defaults.setObject(value, forKey:appDelegate.ToneControlMiddle)
        } else {
            brightnessSlider.value = Float(value)
            cameraWrapper.setExpRev(camera, value: value)
            appDelegate.defaults.setObject(value, forKey:appDelegate.ExpRev)
        }
        appDelegate.defaults.synchronize()
        setBrightnessEnableButtonTimer()
    }
    
    @IBAction func brightnessEnableButtonAction(sender: AnyObject) {
        if brightnessSliderEnable {
            brightnessSliderEnable = false
        } else {
            brightnessSliderEnable = true
            setBrightnessEnableButtonTimer()
        }
        updatebrightnessEnableButton()
    }
    
    func updatebrightnessEnableButton() {
        if brightnessSliderEnable {
            brightnessEnableButton.setImage(UIImage(named: "brightness_selected"), forState: UIControlState.Normal)
            brightnessSlider.hidden = false
        } else {
            brightnessEnableButton.setImage(UIImage(named: "brightness"), forState: UIControlState.Normal)
            brightnessSlider.hidden = true
        }
    }
    
    func setBrightnessEnableButtonTimer() {
        if brightnessSliderDisableTimer != nil && brightnessSliderDisableTimer.valid {
            brightnessSliderDisableTimer.invalidate()
        }
        
        brightnessSliderDisableTimer = NSTimer.scheduledTimerWithTimeInterval(8.0, target: self, selector: Selector("onBrightnessEnableButtonTimer:"), userInfo: nil, repeats: false)
    }
    
    func onBrightnessEnableButtonTimer(timer: NSTimer) {
        //タイムアウトしたのでスライダーを消す
        brightnessSliderEnable = false
        updatebrightnessEnableButton()
    }
    
    
    func UpdateUIattribute(enabled:Bool , hidden:Bool) {
        let camera = AppDelegate.sharedCamera
        let actionType :OLYCameraActionType = camera.actionType()
        shutterButton.enabled = enabled
        digitalTeleconButton.enabled = enabled
        brightnessSlider.enabled = enabled
        brightnessEnableButton.enabled = enabled
        
        shutterButton.hidden = hidden
        batteryLevelImage.hidden = hidden
        mediaRemainLabel.hidden = hidden
        digitalTeleconButton.hidden = hidden
        brightnessSlider.hidden = hidden
        brightnessEnableButton.hidden = hidden
        
        if !cameraWrapper.enableBrightness {
            //明るさ調節不可
            brightnessEnableButton.hidden = true
        }
        
        if (!cameraWrapper.enableBrightness) || (!brightnessSliderEnable) {
            //明るさ調節不可
            brightnessSlider.hidden = true
        }
    }

    // MARK: - LiveView Update
    func camera(camera: OLYCamera!, didUpdateLiveView data: NSData!, metadata: [NSObject : AnyObject]!) {
        var image : UIImage = OLYCameraConvertDataToImage(data,metadata)
        self.liveViewImage.image = image
    }
    
    // MARK: - RecView
    func camera(camera: OLYCamera!, didReceiveCapturedImagePreview data: NSData!, metadata: [NSObject : AnyObject]!) {
        if PostInstagram.canInstagramOpen() {
            let instagramViewController:PostInstagram = PostInstagram()
            instagramViewController.setImageData(data)
            self.view.addSubview(instagramViewController.view)
            self.addChildViewController(instagramViewController)
        }
    }
    
    // MARK: - ConnectionDelegate
    func camera(camera: OLYCamera!, disconnectedByError error: NSError!) {
        //AIRとの接続が解除されたのでViewを閉じる
        println("OLYCamera Disconnected")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - cameraPropertyDelegate
    func camera(camera: OLYCamera!, didChangeCameraProperty name: String!) {
        if name == "BATTERY_LEVEL" {
            updateCameraStatus()
        }
    }
    
    // MARK: - MBProgressHUD
    func showHud(message:String) {
        hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        hud.dimBackground = true
        hud.labelText = message
        hud.mode = MBProgressHUDMode.Indeterminate
        hud.show(true)
    }
    
    func hideHud(message:String , time:NSTimeInterval) {
        hud.labelText = message
        hud.delegate = self
        hud.mode = MBProgressHUDMode.Text
        hud.hide(true, afterDelay: time)
    }
    
    func hudWasHidden(hud: MBProgressHUD!) {
        var camera = AppDelegate.sharedCamera
        if camera.connected {
            //接続が完了したらボタンを押せるようにする
            UpdateUIattribute(true, hidden: false)
            updateCameraStatus()
        } else {
            //Hudが閉じられた時にAIRと接続されていない場合にはViewを閉じる
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    // MARK: - Status Display
    func updateCameraStatus() {
        var camera = AppDelegate.sharedCamera
        //BATTERY_LEVEL
        let battery = camera.cameraPropertyValue("BATTERY_LEVEL", error: nil) as String!
        if (battery != nil) {
            let iconImageName : String! = batteryIconList[battery]
            batteryLevelImage.image = UIImage(named: iconImageName)
        }
        updateCameraMediaRemain()
    }
    
    func updateCameraMediaRemain() {
        dispatch_async(dispatch_get_main_queue(), {
            var camera = AppDelegate.sharedCamera
            if camera.actionType().value == OLYCameraActionTypeMovie.value {
                if !camera.recordingVideo {
                    let second = NSInteger(camera.remainingVideoCapacity % 60)
                    let hour = NSInteger(camera.remainingVideoCapacity / (60 * 60))
                    let min = NSInteger((NSInteger(camera.remainingVideoCapacity) - (hour * 60 * 60) - (second)) / 60)
                    self.mediaRemainLabel.text = NSString(format: "%02d:%02d:%02d", hour,min,second) as String
                }
            } else {
                self.mediaRemainLabel.text = "\(camera.remainingImageCapacity)"
            }
        })
    }
    
    // MARK: - Notification
    func NotificationApplicationBackground(notification : NSNotification?) {
        //バックグラウンドに遷移したのでAIRとの切断処理してViewを閉じる
        var camera = AppDelegate.sharedCamera
        cameraWrapper.disconnect(camera)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func NotificationWatchAppStared(notification : NSNotification?) {
        //AppleWatch側が起動したのでAIRとの切断処理してViewを閉じる
        var camera = AppDelegate.sharedCamera
        cameraWrapper.disconnect(camera)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        
        if keyPath == "remainingImageCapacity" || keyPath == "remainingVideoCapacity" {
            updateCameraMediaRemain()
        }
        
    }

    //MARK:- CoreLocation
    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
        var camera = AppDelegate.sharedCamera
        self.cameraWrapper.setGeoLocation(camera, location: newLocation)
    }
    
    //MARK:- RemoteControl Support
    //内部保持用
    var volumeSlider:UISlider!
    var initialVolume : Float = 0
    func startRemoteControl() {
        let frame:CGRect = CGRectMake(-100, -100, 100, 100)
        var volumeView:MPVolumeView = MPVolumeView(frame: frame)
        volumeView.sizeToFit()
        view.addSubview(volumeView)
        
        //音量のスライダーUIと音量を取得する
        for var i = 0 ; i < volumeView.subviews.count ; i++ {
            let subview: AnyObject = volumeView.subviews[i]
            println(subview)
            println(NSStringFromClass(subview.classForCoder))
            if NSStringFromClass(subview.classForCoder) == "MPVolumeSlider" {
                volumeSlider = subview as! UISlider
                initialVolume = volumeSlider.value
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "NotificationVolumeChange:", name: "AVSystemController_SystemVolumeDidChangeNotification" , object: nil)
    }
    
    func endRemoteControl() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "AVSystemController_SystemVolumeDidChangeNotification", object: nil)
    }
    
    func NotificationVolumeChange(notification : NSNotification?) {
        
        if shutterButton.enabled == true {
            shutterButtonAction(shutterButton)
        }
        volumeSlider.value = initialVolume
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

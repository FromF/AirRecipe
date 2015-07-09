//
//  LiveViewController.swift
//  AirRecipe
//
//  Created by Fuji on 2015/07/01.
//  Copyright (c) 2015年 FromF. All rights reserved.
//

import UIKit
import CoreLocation

class LiveViewController: UIViewController ,CLLocationManagerDelegate ,OLYCameraLiveViewDelegate , OLYCameraConnectionDelegate , MBProgressHUDDelegate {
    
    //
    @IBOutlet weak var liveViewImage: UIImageView!
    @IBOutlet weak var shutterButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    
    //
    //AppDelegate instance
    var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    //CameraKitWrapper
    let cameraWrapper = CameraKitWrapper()
    //MBProgressHUD
    var hud: MBProgressHUD!
    //CoreLocation Serivce
    var locationManager = CLLocationManager()

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
        camera.connectionDelegate = self;
        camera.liveViewDelegate = self

        //接続処理完了まではシャッターボタンは非表示にして動画時の表示変化が違和感を減らす
        self.shutterButton.hidden = true
        showHud(NSLocalizedString("CONNECTING",comment: ""))

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let currentPage = self.appDelegate.defaults.objectForKey(self.appDelegate.CatalogSelectNumber) as! NSInteger
            self.cameraWrapper.connectOPC(currentPage, camera: camera)
            camera.changeLiveViewSize(OLYCameraLiveViewSizeVGA, error: nil)
            dispatch_async(dispatch_get_main_queue(), {
                if camera.connected {
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

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        //スリープ許可
        UIApplication.sharedApplication().idleTimerDisabled = false
        
        //AIRとの切断処理
        var camera = AppDelegate.sharedCamera
        cameraWrapper.disconnect(camera)
        
        //CoreLocation Serivce
        locationManager.stopUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Button
    @IBAction func shutterButtonAction(sender: AnyObject) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            dispatch_async(dispatch_get_main_queue(), {
                self.shutterButton.enabled = false
            })
            var camera = AppDelegate.sharedCamera
            
            self.cameraWrapper.takePicture(camera)
            
            dispatch_async(dispatch_get_main_queue(), {
                self.shutterButton.enabled = true
            })
        })
    }
    
    @IBAction func disconnectButtonAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - LiveView Update
    func camera(camera: OLYCamera!, didUpdateLiveView data: NSData!, metadata: [NSObject : AnyObject]!) {
        var image : UIImage = OLYCameraConvertDataToImage(data,metadata)
        self.liveViewImage.image = image
    }
    
    // MARK: - ConnectionDelegate
    func camera(camera: OLYCamera!, disconnectedByError error: NSError!) {
        //AIRとの接続が解除されたのでViewを閉じる
        println("OLYCamera Disconnected")
        self.dismissViewControllerAnimated(true, completion: nil)
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
            self.shutterButton.hidden = false
        } else {
            //Hudが閉じられた時にAIRと接続されていない場合にはViewを閉じる
            self.dismissViewControllerAnimated(true, completion: nil)
        }
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

    //MARK:- CoreLocation
    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
        var camera = AppDelegate.sharedCamera
        self.cameraWrapper.setGeoLocation(camera, location: newLocation)
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

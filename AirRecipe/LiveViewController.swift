//
//  LiveViewController.swift
//  AirRecipe
//
//  Created by Fuji on 2015/07/01.
//  Copyright (c) 2015年 FromF. All rights reserved.
//

import UIKit

class LiveViewController: UIViewController ,OLYCameraLiveViewDelegate , OLYCameraConnectionDelegate {
    
    //
    @IBOutlet weak var liveViewImage: UIImageView!
    @IBOutlet weak var shutterButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    
    //
    //AppDelegate instance
    var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let cameraWrapper = CameraKitWrapper()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "NotificationApplicationBackground:", name: UIApplicationDidEnterBackgroundNotification , object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "NotificationWatchAppStared:", name: appDelegate.NotificationWatchAppStared as String, object: nil)

        var camera = AppDelegate.sharedCamera
        camera.connectionDelegate = self;
        camera.liveViewDelegate = self

        self.disconnectButton.enabled = false
        self.shutterButton.enabled = false

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let currentPage = self.appDelegate.defaults.objectForKey(self.appDelegate.CatalogSelectNumber) as! NSInteger
            self.cameraWrapper.connectOPC(currentPage, camera: camera)
            camera.changeLiveViewSize(OLYCameraLiveViewSizeVGA, error: nil)
            dispatch_async(dispatch_get_main_queue(), {
                self.disconnectButton.enabled = true
                self.shutterButton.enabled = true
                if camera.actionType().value == OLYCameraActionTypeMovie.value {
                    self.shutterButton.setTitle("REC", forState: UIControlState.Normal)
                    self.shutterButton.setTitle("REC", forState: UIControlState.Selected)
                    self.shutterButton.setTitle("REC", forState: UIControlState.Disabled)
                }
            })
        })
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        var camera = AppDelegate.sharedCamera
        cameraWrapper.disconnect(camera)
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
        //切断通知
        println("OLYCamera Disconnected")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Notification
    func NotificationApplicationBackground(notification : NSNotification?) {
        var camera = AppDelegate.sharedCamera
        cameraWrapper.disconnect(camera)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func NotificationWatchAppStared(notification : NSNotification?) {
        var camera = AppDelegate.sharedCamera
        cameraWrapper.disconnect(camera)
        self.dismissViewControllerAnimated(true, completion: nil)
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

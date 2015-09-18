//
//  RecViewController.swift
//  AirRecipe
//
//  Created by Fuji on 2015/09/16.
//  Copyright (c) 2015年 FromF. All rights reserved.
//

import UIKit
import Social
import AssetsLibrary

class RecViewController: UIViewController , MBProgressHUDDelegate {
    //UI
    @IBOutlet weak var recviewImageView: UIImageView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var twitterButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var instagramButton: UIButton!
    @IBOutlet weak var cameraRollButton: UIButton!
    
    //AppDelegate instance
    var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    //RecView Image Store
    var recviewImage:UIImage!
    //撮影日付
    var originalDateTime:String = ""
    //MBProgressHUD
    var hud: MBProgressHUD!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "NotificationCloseLiveViewContoller:", name: appDelegate.NotificationCloseLiveViewContoller as String, object: nil)
        
        //
        recviewImageView.image = recviewImage
        
        //
        //日付生成
        var dfDateTime:NSDateFormatter = NSDateFormatter()
        dfDateTime.dateFormat = "yyyy:MM:dd HH:mm:ss"
        originalDateTime = dfDateTime.stringFromDate(NSDate())
        
        //Twitter
        if !SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
            twitterButton.enabled = false
        }
        
        //Facebook
        if !SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook) {
            facebookButton.enabled = false
        }
        
        //Instagram
        if !PostInstagram.canInstagramOpen() {
            instagramButton.enabled = false
        }
        
        //CameraRoll
        let status = ALAssetsLibrary.authorizationStatus()
        switch(status) {
            case .Authorized:    //写真へのアクセスが許可されている
                break
            case .NotDetermined: //写真へのアクセスを許可するか選択されていない
                break
            case .Restricted:    //設定 > 一般 > 機能制限で利用が制限されている
                cameraRollButton.enabled = false
            case .Denied:        //設定 > プライバシー > 写真で利用が制限されている
                cameraRollButton.enabled = false
            default:
                break
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: appDelegate.NotificationCloseLiveViewContoller as String, object: nil)
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
    
    // MARK: - Notification
    func NotificationCloseLiveViewContoller(notification : NSNotification?) {
        //LiveViewControllerが閉じたので本画面も閉じる
        dismissViewControllerAnimated(false, completion: nil)
    }
    
    // MARK: - Button
    @IBAction func closeButtonAction(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func twitterButtonAction(sender: AnyObject) {
        let vc = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
        vc.setInitialText("\n#olympusair")
        vc.addImage(recviewImage)
        vc.completionHandler = {(result:SLComposeViewControllerResult) -> Void in
            switch result {
            case SLComposeViewControllerResult.Done:
                print("Done")
                dispatch_async(dispatch_get_main_queue(), {
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
            case SLComposeViewControllerResult.Cancelled:
                print("Cancel")
                dispatch_async(dispatch_get_main_queue(), {
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
            }
        }
        self.presentViewController(vc, animated: true, completion: nil)
    }
    @IBAction func facebookButtonAction(sender: AnyObject) {
        let vc = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
        vc.addImage(recviewImage)
        vc.completionHandler = {(result:SLComposeViewControllerResult) -> Void in
            switch result {
            case SLComposeViewControllerResult.Done:
                print("Done")
                dispatch_async(dispatch_get_main_queue(), {
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
            case SLComposeViewControllerResult.Cancelled:
                print("Cancel")
                dispatch_async(dispatch_get_main_queue(), {
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
            }
        }
        self.presentViewController(vc, animated: true, completion: nil)
    }
    @IBAction func instagramButtonAction(sender: AnyObject) {
        let instagramViewController:PostInstagram = PostInstagram()
        instagramViewController.setImage(recviewImage)
        self.view.addSubview(instagramViewController.view)
        self.addChildViewController(instagramViewController)
    }
    @IBAction func cameraRollButtonAction(sender: AnyObject) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let semaphore:dispatch_semaphore_t = dispatch_semaphore_create(0);
            
            //Exif格納領域
            var exifDict :NSMutableDictionary = NSMutableDictionary()
            
            exifDict[kCGImagePropertyExifDateTimeOriginal as String] = self.originalDateTime
            exifDict[kCGImagePropertyExifDateTimeDigitized as String] = self.originalDateTime
            
            //アプリ名を入れる
            exifDict[kCGImagePropertyExifUserComment as String] = "AirRecipe"
            
            //メタデータを作成する
            var metaData = NSMutableDictionary()
            metaData[kCGImagePropertyExifDictionary as String] = exifDict
            
            //メタデータを保存するためにはAssetsLibraryを使用する
            var assetLibrary : ALAssetsLibrary = ALAssetsLibrary()
            assetLibrary.writeImageToSavedPhotosAlbum(self.recviewImage.CGImage,metadata: metaData as [NSObject : AnyObject], completionBlock:{
                (assetURL: NSURL!, error: NSError!) -> Void in
                println("Success")
                dispatch_semaphore_signal(semaphore)
            })
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            dispatch_async(dispatch_get_main_queue(), {
                self.showHud(NSLocalizedString("SAVE_COMPLETE",comment: ""))
                self.hideHud(NSLocalizedString("SAVE_COMPLETE",comment: "") , time:2.0)
            })
        })
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
        dismissViewControllerAnimated(true, completion: nil)
    }

}

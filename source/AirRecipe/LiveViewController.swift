//
//  LiveViewController.swift
//  AirRecipe
//
//  Created by 藤　治仁 on 2018/02/22.
//  Copyright © 2018年 Personal. All rights reserved.
//

import UIKit
import MBProgressHUD

class LiveViewController: UIViewController , OLYCameraLiveViewDelegate , OLYCameraConnectionDelegate , OLYCameraPropertyDelegate , OLYCameraRecordingSupportsDelegate , MBProgressHUDDelegate {
    
    @IBOutlet weak var liveViewImage: CameraLiveImageView!
    @IBOutlet weak var shutterButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var brightnessEnableButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var digitalTeleconButton: UIButton!
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var batteryLevelImage: UIImageView!
    @IBOutlet weak var mediaRemainLabel: UILabel!
    
    ///CameraKitWrapper
    private let cameraWrapper = CameraKitWrapper()
    
    ///BatteryLevelMeter
    private let batteryIconList = [
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
    
    ///撮影確認画像を保持する
    private var recviewImage:UIImage?
    
    ///スライダータイマー用のタイマーインスタンス
    private var brightnessSliderHiddenTimer:Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //CameraKitSetting
        cameraWrapper.cameraKit.connectionDelegate = self
        cameraWrapper.cameraKit.liveViewDelegate = self
        cameraWrapper.cameraKit.recordingSupportsDelegate  = self
        cameraWrapper.cameraKit.cameraPropertyDelegate = self
        cameraWrapper.cameraKit.addObserver(self, forKeyPath: "remainingImageCapacity", options: [], context: nil)
        cameraWrapper.cameraKit.addObserver(self, forKeyPath: "remainingVideoCapacity", options: [], context: nil)

        //バックグラウンド通知設定
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(viewWillResignActive(_:)),
            name: NSNotification.Name.UIApplicationWillResignActive,
            object: nil
        )
        
        //明るさボタン初期化
        updatebrightnessEnableButton(isInit: true)
        
        DispatchQueue.global(qos: .default).async {
            DispatchQueue.main.async {
                self.updateUIattribute(isEnabled: false, isHidden: true)
                self.showHud(NSLocalizedString("CONNECTING",comment: ""))
            }
            let sceneInstance = SceneManager.shared
            let currentNumber = sceneInstance.getUserSelectNumber()
            let cameraKitProperty = sceneInstance.getCameraKitProperty(number: currentNumber)
            let result = self.cameraWrapper.connectOPC(cameraKitProperty: cameraKitProperty)
            
            DispatchQueue.main.async {
                if result {
                    if sceneInstance.isExpRev {
                        let expRev = sceneInstance.getExpRev()
                        self.brightnessSlider.maximumValue = Float(SceneManager.ExpRev.max.rawValue - 1)
                        self.brightnessSlider.minimumValue = 0
                        self.brightnessSlider.value = Float(expRev.rawValue)
                    } else if sceneInstance.isToneControl {
                        let toneControl = sceneInstance.getToneControl()
                        self.brightnessSlider.maximumValue = Float(SceneManager.ToneControl.max.rawValue - 1)
                        self.brightnessSlider.minimumValue = 0
                        self.brightnessSlider.value = Float(toneControl.rawValue)
                    }
                    
                    self.hideHud(NSLocalizedString("CONNECTCOMPLETE",comment: "") , time:0.1)
                } else {
                    self.hideHud(NSLocalizedString("CONNECTFAIL",comment: "") , time:1.0)
                }
            }
        }
    }
    
    deinit {
        debugLog("")
        //バックグラウンド通知解除
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name.UIApplicationWillResignActive,
            object: nil
        )
        cameraWrapper.cameraKit.removeObserver(self, forKeyPath: "remainingImageCapacity")
        cameraWrapper.cameraKit.removeObserver(self, forKeyPath: "remainingVideoCapacity")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Button
    @IBAction func shutterButtonAction(_ sender: Any) {
        let sceneInstance = SceneManager.shared
        //セマフォ作成
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.global(qos: .default).async {
            DispatchQueue.main.async {
                self.updateUIattribute(isEnabled: false, isHidden: false)
            }
            if sceneInstance.isClipsMovie {
                self.cameraWrapper.takeMovie(isClips: true, completionHandler: { (result) in
                    //セマフォシグナル
                    semaphore.signal()
                })
                //セマフォ待ち
                _ = semaphore.wait(timeout:.distantFuture)
            } else if sceneInstance.isHDRShooting {
                _ = self.cameraWrapper.takeHDRShooting()
            } else {
                if self.cameraWrapper.takeNormal(completionHandler: { (result) in
                    //セマフォシグナル
                    semaphore.signal()
                }) {
                    //セマフォ待ち
                    _ = semaphore.wait(timeout:.distantFuture)
                }
            }
            DispatchQueue.main.async {
                self.updateUIattribute(isEnabled: true, isHidden: false)
            }
        }
    }
    
    @IBAction func disconnectButtonAction(_ sender: Any) {
        closeLiveViewController()
    }
    
    @IBAction func brightnessEnableButtonAction(_ sender: Any) {
        updatebrightnessEnableButton(isInit: false)
        startBrightnessSliderHiddenTimer()
    }
    
    @IBAction func brightnessSliderAction(_ sender: UISlider) {
        startBrightnessSliderHiddenTimer()
        let sceneInstance = SceneManager.shared
        if sceneInstance.isExpRev {
            if let expRev = SceneManager.ExpRev(rawValue: Int(round(sender.value)) ) {
                sceneInstance.setExpRev(value: expRev)
                cameraWrapper.setPropertyValue(name: expRev.property(), value: expRev.string())
            }
        } else if sceneInstance.isToneControl {
            if let toneControl = SceneManager.ToneControl(rawValue: Int(round(sender.value)) ) {
                sceneInstance.setToneControl(value: toneControl)
                cameraWrapper.setPropertyValue(name: toneControl.property(), value: toneControl.string())
            }
        }
    }
    
    @IBAction func digitalTeleconButtonAction(_ sender: Any) {
        DispatchQueue.global(qos: .default).async {
            DispatchQueue.main.async {
                self.updateUIattribute(isEnabled: false, isHidden: false)
            }
            self.cameraWrapper.changeDigitalTelecon()
            self.updateCameraStatus()
            DispatchQueue.main.async {
                self.updateUIattribute(isEnabled: true, isHidden: false)
            }
        }
    }
    
    @IBAction func shareButtonAction(_ sender: UIButton) {
        if let shareImage = recviewImage {
            let shareItems = [shareImage]
            let controller = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
            controller.popoverPresentationController?.sourceView = sender
            present(controller, animated: true, completion: nil)
        }

    }
    
    // MARK: - TouchAF処理
    @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
        var result = true
        
        let point = liveViewImage.point(with: sender)
        
        if result {
            if !liveViewImage.contains(point) {
                result = false
            }
        }
        
        if result {
            UIApplication.shared.beginIgnoringInteractionEvents()
            
            let focusWidth = CGFloat(0.125)
            var focusHeight = CGFloat(0.125)
            let imageWidth = liveViewImage.intrinsicContentSize.width
            let imageHeight = liveViewImage.intrinsicContentSize.height
            
            if imageWidth > imageHeight {
                focusHeight *= imageWidth / imageHeight
            } else {
                focusHeight *= imageHeight / imageWidth
            }
            
            let focusRect = CGRect(x: point.x - (focusWidth / 2), y: point.y - (focusHeight / 2), width: focusWidth, height: focusHeight)
            
            liveViewImage.showFocusFrame(focusRect, status: CameraFocusFrameStatusRunning)

            DispatchQueue.global(qos: .default).async {
                let result = self.cameraWrapper.setAfPoint(point: point)
                DispatchQueue.main.async {
                    if result {
                        self.liveViewImage.showFocusFrame(focusRect, status: CameraFocusFrameStatusFocused)
                    } else {
                        self.liveViewImage.showFocusFrame(focusRect, status: CameraFocusFrameStatusFailed, duration: 1.0)
                    }
                    UIApplication.shared.endIgnoringInteractionEvents()
                }
            }
        }
    }
    
    // MARK: - UI Control
    /// UIパーツの有効無効、表示非表示を設定する
    ///
    /// - Parameters:
    ///   - isEnabled: 有効無効設定
    ///   - isHidden: 表示非表示設定
    private func updateUIattribute(isEnabled:Bool , isHidden:Bool) {
        let sceneInstance = SceneManager.shared

        shutterButton.isEnabled = isEnabled
        brightnessEnableButton.isEnabled = isEnabled
        brightnessSlider.isEnabled = isEnabled
        shareButton.isEnabled = isEnabled
        digitalTeleconButton.isEnabled = isEnabled
        mediaRemainLabel.isEnabled = isEnabled
        
        shutterButton.isHidden = isHidden
        brightnessEnableButton.isHidden = isHidden
        digitalTeleconButton.isHidden = isHidden
        if isHidden {
            shareButton.isHidden = isHidden
            brightnessSlider.isHidden = isHidden
            batteryLevelImage.isHidden = isHidden
            mediaRemainLabel.isHidden = isHidden
        }

        if !sceneInstance.isToneControl && !sceneInstance.isExpRev {
            //明るさ調整不可
            brightnessEnableButton.isHidden = true
            brightnessSlider.isHidden = true
        }
    }
    
    /// 明るさボタンのアイコン更新とスライダー表示非表示
    ///
    /// - Parameter isInit: 初期化にするか否か
    private func updatebrightnessEnableButton(isInit:Bool) {
        if brightnessSlider.isHidden && !isInit {
            brightnessEnableButton.setImage(UIImage(named: "brightness_selected"), for: .normal)
            brightnessSlider.isHidden = false
        } else {
            brightnessEnableButton.setImage(UIImage(named: "brightness"), for: .normal)
            brightnessSlider.isHidden = true
        }
    }
    
    /// スライダー非表示タイマースタート
    private func startBrightnessSliderHiddenTimer() {
        if let timer = brightnessSliderHiddenTimer {
            if timer.isValid {
                timer.invalidate()
            }
        }
        
        brightnessSliderHiddenTimer = Timer.scheduledTimer(timeInterval: 8.0,
                                                           target: self,
                                                           selector: #selector(self.startBrightnessSliderHiddenTimerInterrupt(_:)),
                                                           userInfo: nil,
                                                           repeats: false)
        
    }
    
    /// スライダー非表示タイマータイムアウト
    ///
    /// - Parameter timer: タイマーインスタンス
    @objc func startBrightnessSliderHiddenTimerInterrupt(_ timer: Timer) {
        //タイムアウトしたのでスライダーを消す
        updatebrightnessEnableButton(isInit: true)
    }

    /// カメラステータスを表示更新する
    private func updateCameraStatus() {
        DispatchQueue.main.async {
            if let batteryLevel = self.cameraWrapper.getPropertyValue(name: "BATTERY_LEVEL") , let batteryIconName = self.batteryIconList[batteryLevel] {
                self.batteryLevelImage.image = UIImage(named:batteryIconName)
                if self.batteryLevelImage.isHidden {
                    self.batteryLevelImage.isHidden = false
                }
            }
            if let remain = self.cameraWrapper.getMediaRemain() {
                if self.mediaRemainLabel.isEnabled {
                    self.mediaRemainLabel.text = remain
                    if self.mediaRemainLabel.isHidden {
                        self.mediaRemainLabel.isHidden = false
                    }
                }
            }
            
            if self.cameraWrapper.digitalZoomCurrent == 3.0 {
                self.digitalTeleconButton.setImage(UIImage(named:"ar_icn_dtelecon_x3"), for: .normal)
                self.digitalTeleconButton.setImage(UIImage(named:"ar_icn_dtelecon_x3_pushed"), for: .highlighted)
            } else if self.cameraWrapper.digitalZoomCurrent == 2.0 {
                self.digitalTeleconButton.setImage(UIImage(named:"ar_icn_dtelecon_x2"), for: .normal)
                self.digitalTeleconButton.setImage(UIImage(named:"ar_icn_dtelecon_x2_pushed"), for: .highlighted)
            } else {
                self.digitalTeleconButton.setImage(UIImage(named:"ar_icn_dtelecon_x1"), for: .normal)
                self.digitalTeleconButton.setImage(UIImage(named:"ar_icn_dtelecon_x1_pushed"), for: .highlighted)
            }
            
        }
    }

    // MARK: - OLYCameraLiveViewDelegate
    /// ライブビュー更新通知
    ///
    /// - Parameters:
    ///   - camera: OLYCameraインスタンス
    ///   - data: 画像データ
    ///   - metadata: メタデータ
    func camera(_ camera: OLYCamera!, didUpdateLiveView data: Data!, metadata: [AnyHashable : Any]!) {
        if let image = OLYCameraConvertDataToImage(data, metadata) {
            liveViewImage.image = image
        }
    }
    
    // MARK: - OLYCameraRecordingSupportsDelegate
    /// 撮影確認画像生成通知
    ///
    /// - Parameters:
    ///   - camera: OLYCameraインスタンス
    ///   - data: 画像データ
    ///   - metadata: メタデータ
    func camera(_ camera: OLYCamera!, didReceiveCapturedImagePreview data: Data!, metadata: [AnyHashable : Any]!) {
        if let image = OLYCameraConvertDataToImage(data, metadata) {
            recviewImage = image
            if shareButton.isHidden {
                shareButton.isHidden = false
            }
        }
    }
    
    // MARK: - OLYCameraConnectionDelegate
    /// カメラとの切断通知
    ///
    /// - Parameters:
    ///   - camera: OLYCameraインスタンス
    ///   - error: エラー詳細
    func camera(_ camera: OLYCamera!, disconnectedByError error: Error!) {
        debugLog("OLYCamera Disconnected")
        closeLiveViewController()
    }
    // MARK: - OLYCameraPropertyDelegate
    /// カメラ設定変化通知
    ///
    /// - Parameters:
    ///   - camera: OLYCameraインスタンス
    ///   - name: プロパティー名
    func camera(_ camera: OLYCamera!, didChangeCameraProperty name: String!) {
        //バッテリー変化通知
        if name == "BATTERY_LEVEL" {
            updateCameraStatus()
        }
    }
    
    // MARK: - Notification
    /// バックグラウンド遷移通知
    ///
    /// - Parameter notification: インスタンス
    @objc func viewWillResignActive(_ notification: Notification?) {
        debugLog("")
        //バックグラウンドに遷移したのでAIRとの切断処理してViewを閉じる
        closeLiveViewController()
    }

    // MARK: - Functions
    /// カメラとの切断処理
    private func closeLiveViewController() {
        cameraWrapper.disconnect(powerOff: false)
        
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - NSKeyValueObserving
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath {
            if keyPath == "remainingImageCapacity" || keyPath == "remainingVideoCapacity" {
                updateCameraStatus()
            }
        }
    }
    
    // MARK: - MBProgressHUD
    ///処理中UI用
    fileprivate var hud : MBProgressHUD!
    
    func showHud(_ message:String) {
        hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.label.text = message
        hud.mode = .indeterminate
        hud.backgroundView.style = .solidColor
        hud.backgroundView.color = UIColor.init(white: 0.0 , alpha: 0.2)
        hud.show(animated: true)
    }
    
    func hideHud(_ message:String , time:TimeInterval) {
        hud.label.text = message
        hud.delegate = self
        hud.hide(animated: true, afterDelay: time)
    }
    
    func showHudOneShot(_ message:String , time:TimeInterval) {
        hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.label.text = message
        hud.mode = .indeterminate
        hud.backgroundView.style = .solidColor
        hud.backgroundView.color = UIColor.init(white: 0.0 , alpha: 0.2)
        hud.show(animated: true)
        hud.hide(animated: true, afterDelay: time)
    }
    
    func hudWasHidden(_ hud: MBProgressHUD) {
        //MBProgressHUDが消えたときに呼ばれる
        if cameraWrapper.cameraKit.connected {
            updateUIattribute(isEnabled: true, isHidden: false)
            updateCameraStatus()
        } else {
            closeLiveViewController()
        }
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

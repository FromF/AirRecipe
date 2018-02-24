//
//  ViewController.swift
//  AirRecipe
//
//  Created by 藤　治仁 on 2018/02/21.
//  Copyright © 2018年 Personal. All rights reserved.
//

import UIKit
import MBProgressHUD

class ViewController: UIViewController , UIScrollViewDelegate , MBProgressHUDDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var connectCameraButton: UIButton!
    @IBOutlet weak var openBlogButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        scrollView.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updateSampleImage()
        updateTextView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Button Action
    @IBAction func connectCameraButtonAction(_ sender: Any) {
        connectWiFi()
    }
    
    @IBAction func openBlogButtonAction(_ sender: Any) {
        UIApplication.shared.open(URL(string: "http://ameblo.jp/ux-t298/theme-10091245629.html")!, options: [:], completionHandler: nil)
    }
    
    @IBAction func settingButtonAction(_ sender: Any) {
        performSegue(withIdentifier: "goSetting", sender: nil)
    }
    
    // MARK: - UIPageControl changeValue
    @IBAction func pageControlAction(_ sender: UIPageControl) {
        let scrollViewWidth = scrollView.frame.size.width
        let currentNumber = sender.currentPage
        scrollView.contentOffset = CGPoint(x: scrollViewWidth * CGFloat(currentNumber), y: 0)
    }
    
    // MARK: - 撮影モード関連
    func updateSampleImage() {
        let sceneInstance = SceneManager.shared
        let scrollViewWidth = scrollView.frame.size.width
        let scrollViewHeight = scrollView.frame.size.height
        
        //スクロールビューの中をすべて消す
        for subview in scrollView.subviews {
            subview.removeFromSuperview()
        }
        
        //最大ページ数を設定する
        pageControl.numberOfPages = sceneInstance.sceneMaxNumber
        
        //スクロールビューのサイズを決定する
        scrollView.contentSize = CGSize(width: scrollViewWidth * CGFloat(sceneInstance.sceneMaxNumber), height: scrollViewHeight)
        
        for number in 0..<sceneInstance.sceneMaxNumber {
            let imageView = UIImageView(frame: CGRect(x: scrollViewWidth * CGFloat(number), y: 0, width: scrollViewWidth, height: scrollViewHeight))
            imageView.image = UIImage(named: sceneInstance.getSampleImageName(number: number)!)
            imageView.backgroundColor = .gray
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            scrollView.addSubview(imageView)
        }
        
        //最後に選択した場所に移動する
        let currentNumber = sceneInstance.getUserSelectNumber()
        pageControl.currentPage = currentNumber
        scrollView.contentOffset = CGPoint(x: scrollViewWidth * CGFloat(currentNumber), y: 0)
    }
    
    func updateTextView() {
        let sceneInstance = SceneManager.shared
        let currentNumber = sceneInstance.getUserSelectNumber()
        let textTapple = sceneInstance.getTextInfo(number: currentNumber)
        
        if let title = textTapple.title , let detail = textTapple.detail {
            let text = NSMutableAttributedString()
            text.append(NSAttributedString(string: title, attributes: [.underlineStyle:1, .font:UIFont.boldSystemFont(ofSize: 12.0)]))
            text.append(NSAttributedString(string: "\n"))
            text.append(NSAttributedString(string: detail))
            
            textView.attributedText = text
        }
    }
    
    // MARK: - ScrollView Delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let sceneInstance = SceneManager.shared
        let scrollViewWidth = scrollView.frame.size.width
        let currentPage = Int(scrollView.contentOffset.x / scrollViewWidth)
        
        sceneInstance.setUserSelectNumber(number: currentPage)
        pageControl.currentPage = currentPage
        updateTextView()
    }
    
    // MARK: - 接続処理
    func connectWiFi() {
        let wifiManager = WifiManager.shared
        let cameraWrapper = CameraKitWrapper()
        if wifiManager.isAutoConnect && !wifiManager.isConnectWifi() {
            DispatchQueue.global(qos: .default).async {
                DispatchQueue.main.async {
                    self.showHud(NSLocalizedString("CONNECTING",comment: ""))
                }
                
                //SSID接続開始
                wifiManager.connectWiFi()
                var result = true
                if result {
                    //SSIDが認識されるまで待つ
                    result = wifiManager.waitConnectWiFi(timeOut: 15)
                }
                if result {
                    //AIRとのコマンド通信ができるか待つ
                    result = cameraWrapper.waitConnectWiFi(timeOut: 5)
                }
                
                DispatchQueue.main.async {
                    if result {
                        self.hideHud(NSLocalizedString("CONNECTCOMPLETE",comment: "") , time:1.0)
                    } else {
                        self.hideHud(NSLocalizedString("CONNECTFAIL",comment: "") , time:5.0)
                    }
                }
            }
        } else {
            performSegue(withIdentifier: "goLiveView", sender: nil)
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
        let wifiManager = WifiManager.shared
        if wifiManager.isConnectWifi() {
            performSegue(withIdentifier: "goLiveView", sender: nil)
        }
    }
}


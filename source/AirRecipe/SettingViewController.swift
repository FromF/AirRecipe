//
//  SettingViewController.swift
//  AirRecipe
//
//  Created by 藤　治仁 on 2018/02/24.
//  Copyright © 2018年 Personal. All rights reserved.
//

import UIKit
import MBProgressHUD

class SettingViewController: UIViewController , MBProgressHUDDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var wifiAutoConnectTitle: UILabel!
    @IBOutlet weak var wifiSSIDTitle: UILabel!
    @IBOutlet weak var wifiSSIDValue: UILabel!
    @IBOutlet weak var wifiPasswordTitle: UILabel!
    @IBOutlet weak var wifiPasswordValue: UILabel!
    @IBOutlet weak var autoPowerOnTitle: UILabel!
    @IBOutlet weak var wifiAutoConnectSwitch: UISwitch!
    @IBOutlet weak var autoPowerOnSwitch: UISwitch!
    @IBOutlet weak var closeButton: UIButton!
    
    ///WiFiマネージャのインスタンス
    private let wifiManager = WifiManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        textView.text = "この画面でWiFi設定を有効にすると自動的にWiFi接続を切り替えます。\n自動電源ONを有効にするとOA.CentralアプリでペアリングしているOLYMPUS AIR A01の電源を自動でオンにします。"
        updateStatus()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Button
    @IBAction func closeButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Switch
    @IBAction func wifiAutoConnectSwitchAction(_ sender: UISwitch) {
        if sender.isOn {
            let alertController = UIAlertController(title: "WiFi接続情報入力", message: "SSIDとパスワードを入力してください", preferredStyle: .alert)
            
            let confirmAction = UIAlertAction(title: "完了", style: .default) { (_) in
                if let ssid = alertController.textFields?[0].text , let password = alertController.textFields?[1].text {
                    self.wifiManager.isAutoConnect = true
                    self.wifiManager.ssid = ssid
                    self.wifiManager.password = password
                    self.updateStatus()
                    self.connectWiFi()
                }
            }
            
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { (_) in }
            
            alertController.addTextField { (textField) in
                if let ssid = self.wifiManager.ssid {
                    textField.text = ssid
                } else {
                    textField.text = "AIR-A01-"
                }
                textField.placeholder = "SSIDを入力してください"
            }
            alertController.addTextField { (textField) in
                if let password = self.wifiManager.password {
                    textField.text = password
                }
                textField.placeholder = "パスワードを入力してください"
            }
            
            alertController.addAction(confirmAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func autoPowerOnSwitchAction(_ sender: Any) {
    }
    
    // MARK: - UI Control
    private func updateStatus() {
        if let ssid = wifiManager.ssid  , let password = wifiManager.password {
            wifiSSIDValue.text = ssid
            wifiPasswordValue.text = password
        } else {
            wifiSSIDValue.text = ""
            wifiPasswordValue.text = ""
        }
        wifiAutoConnectSwitch.isOn = wifiManager.isAutoConnect
    }
    
    // MARK: - 接続処理
    func connectWiFi() {
        if !wifiManager.isConnectWifi() {
            DispatchQueue.global(qos: .default).async {
                DispatchQueue.main.async {
                    self.showHud(NSLocalizedString("CONNECTING",comment: ""))
                }
                
                self.wifiManager.connectWiFi()
                let result = self.wifiManager.waitConnectWiFi(timeOut: 5)
                
                DispatchQueue.main.async {
                    if result {
                        self.hideHud(NSLocalizedString("CONNECTCOMPLETE",comment: "") , time:1.0)
                    } else {
                        self.hideHud(NSLocalizedString("CONNECTFAIL",comment: "") , time:5.0)
                    }
                }
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

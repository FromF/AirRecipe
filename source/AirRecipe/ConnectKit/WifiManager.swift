//
//  WifiManager.swift
//  AirRecipe
//
//  Created by 藤　治仁 on 2018/02/24.
//  Copyright © 2018年 Personal. All rights reserved.
//

import UIKit
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

class WifiManager: NSObject {
    /// シングルトン
    static let shared = WifiManager()
    
    var ssid:String?
    var password:String?
    var isAutoConnect:Bool = false
    
    ///UserDefaltsのキー
    private let userSSIDKey = "ssid"
    private let userPasswordKey = "password"
    private let userIsAutoConnectKey = "isAutoConnect"

    override init() {
        super.init()
        
        // UserDefaultsのインスタンスを生成
        let settings = UserDefaults.standard
        // UserDefaultsに初期値を登録
        let defaults = [userIsAutoConnectKey:false]
        settings.register(defaults: defaults)
        
        //設定を復元
        isAutoConnect = settings.bool(forKey: userIsAutoConnectKey)
        ssid = settings.string(forKey: userSSIDKey)
        password = settings.string(forKey: userPasswordKey)
    }
    
    deinit {
        registSetting()
    }
    
    
    func connectWiFi() {
        registSetting()
        if let ssid = ssid , let password = password {
            let manager = NEHotspotConfigurationManager.shared
            let isWEP = false   //WPA/WPA2の場合はここをfalseにする
            let hotspotConfiguration = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: isWEP)
            hotspotConfiguration.joinOnce = true    //アプリがアクティブな時だけ接続
            hotspotConfiguration.lifeTimeInDays = 1 //設定が有効な期間
            
            manager.apply(hotspotConfiguration) { (error) in
                if let error = error {
                    errorLog(error)
                } else {
                    debugLog("success")
                }
            }
        } else {
            errorLog("noset ssid & password")
        }
    }
    
    func isConnectWifi() -> Bool {
        var result = false
        
        if let interface = CNCopySupportedInterfaces() {
            for i in 0..<CFArrayGetCount(interface) {
                let interfaceName: UnsafeRawPointer = CFArrayGetValueAtIndex(interface, i)
                let rec = unsafeBitCast(interfaceName, to: AnyObject.self)
                if let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)" as CFString), let interfaceData = unsafeInterfaceData as? [String : AnyObject] {
                    // connected wifi
                    debugLog("BSSID: \(interfaceData["BSSID"]), SSID: \(interfaceData["SSID"]), SSIDDATA: \(interfaceData["SSIDDATA"])")
                    if let connect_ssid = interfaceData["SSID"] as? String {
                        if connect_ssid == ssid {
                            result = true
                        }
                    }
                } else {
                    errorLog("not connected wifi")
                }
            }
        }
        
        return result
    }
    
    func waitConnectWiFi(timeOut:Int) -> Bool {
        var result = false

        for _ in 0..<(timeOut * 2) {
            result = isConnectWifi()
            if result {
                break
            } else {
                Thread.sleep(forTimeInterval: 0.5)
            }
        }

        return result
    }
    
    private func registSetting() {
        //設定保持
        let settings = UserDefaults.standard
        settings.set(isAutoConnect, forKey: userIsAutoConnectKey)
        if let ssid = ssid {
            settings.set(ssid, forKey: userSSIDKey)
        }
        if let password = password {
            settings.set(password, forKey: userPasswordKey)
        }
        settings.synchronize()
    }
    
    
    
}

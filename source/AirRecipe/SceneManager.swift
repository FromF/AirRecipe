//
//  SceneManager.swift
//  AirRecipe
//
//  Created by 藤　治仁 on 2018/02/21.
//  Copyright © 2018年 Personal. All rights reserved.
//

import UIKit

class SceneManager: NSObject {
    ///シングルトン
    static let shared = SceneManager()
    
    ///選択可能なシーン数
    let sceneMaxNumber = 8
    
    ///Clips Mode Flag
    var isClipsMovie = false
    ///HDR Mode Flag
    var isHDRShooting = false
    ///ToneControl Flag
    var isToneControl = false
    ///ExpRev Flag
    var isExpRev = false

    ///UserDefaltsのキー
    private let userSelectKey = "SelectNumber"
    private let userToneControlKey = "TONE_CONTROL_MIDDLE"
    private let userExprevKey = "EXPREV"

    enum ToneControl:Int {
        case m7
        case m6
        case m5
        case m4
        case m3
        case m2
        case m1
        case zero
        case p1
        case p2
        case p3
        case p4
        case p5
        case p6
        case p7
        case max
        
        func string() -> String {
            switch self {
            case .m7:
                return "-7"
            case .m6:
                return "-6"
            case .m5:
                return "-5"
            case .m4:
                return "-4"
            case .m3:
                return "-3"
            case .m2:
                return "-2"
            case .m1:
                return "-1"
            case .zero:
                return "0"
            case .p1:
                return "+1"
            case .p2:
                return "+2"
            case .p3:
                return "+3"
            case .p4:
                return "+4"
            case .p5:
                return "+5"
            case .p6:
                return "+6"
            case .p7:
                return "+7"
            case .max:
                return "max"
            }
        }
        
        func property() -> String {
            return "TONE_CONTROL_MIDDLE"
        }
    }
    
    enum ExpRev:Int {
        case m50
        case m47
        case m43
        case m40
        case m37
        case m33
        case m30
        case m27
        case m23
        case m20
        case m17
        case m13
        case m10
        case m07
        case m03
        case zero
        case p03
        case p07
        case p10
        case p13
        case p17
        case p20
        case p23
        case p27
        case p30
        case p33
        case p37
        case p40
        case p43
        case p47
        case p50
        case max

        func string() -> String {
            switch self {
            case .m50:
                return "-5.0"
            case .m47:
                return "-4.7"
            case .m43:
                return "-4.3"
            case .m40:
                return "-4.0"
            case .m37:
                return "-3.7"
            case .m33:
                return "-3.3"
            case .m30:
                return "-3.0"
            case .m27:
                return "-2.7"
            case .m23:
                return "-2.3"
            case .m20:
                return "-2.0"
            case .m17:
                return "-1.7"
            case .m13:
                return "-1.3"
            case .m10:
                return "-1.0"
            case .m07:
                return "-0.7"
            case .m03:
                return "-0.3"
            case .zero:
                return "0.0"
            case .p03:
                return "+0.3"
            case .p07:
                return "+0.7"
            case .p10:
                return "+1.0"
            case .p13:
                return "+1.3"
            case .p17:
                return "+1.7"
            case .p20:
                return "+2.0"
            case .p23:
                return "+2.3"
            case .p27:
                return "+2.7"
            case .p30:
                return "+3.0"
            case .p33:
                return "+3.3"
            case .p37:
                return "+3.7"
            case .p40:
                return "+4.0"
            case .p43:
                return "+4.3"
            case .p47:
                return "+4.7"
            case .p50:
                return "+5.0"
            case .max:
                return "max"
            }
        }
        
        func property() -> String {
            return "EXPREV"
        }
    }

    
    override init() {
        super.init()
        
        // UserDefaultsのインスタンスを生成
        let settings = UserDefaults.standard
        // UserDefaultsに初期値を登録
        let defaults = [userSelectKey:0 ,
                        userToneControlKey: ToneControl.zero.rawValue,
                        userExprevKey:ExpRev.zero.rawValue]
        settings.register(defaults: defaults)
    }
    
    // MARK: - cameraMode
    /// 撮影モードの説明
    ///
    /// - Parameter number: 選択番号
    /// - Returns: タイトルと説明
    func getTextInfo(number:Int) -> (title:String? , detail:String? ) {
        var textInfo:(title:String? , detail:String?)
        
        //各種設定に応じた説明文を選択
        switch(number) {
        case 0:
            textInfo = ( NSLocalizedString("SINGLE_TITLE",comment: "") , NSLocalizedString("SINGLE",comment: ""))
        case 1:
            textInfo = ( NSLocalizedString("CONTINUOUS_TITLE",comment: "") , NSLocalizedString("CONTINUOUS",comment: ""))
        case 2:
            textInfo = ( NSLocalizedString("CLIPS_TITLE",comment: "") , NSLocalizedString("CLIPS",comment: ""))
        case 3:
            textInfo = ( NSLocalizedString("HDR_TITLE",comment: "") , NSLocalizedString("HDR",comment: ""))
        case 4:
            textInfo = ( NSLocalizedString("MOON_TITLE",comment: "") , NSLocalizedString("MOON",comment: ""))
        case 5:
            textInfo = ( NSLocalizedString("WATERFALL_TITLE",comment: "") , NSLocalizedString("WATERFALL",comment: ""))
        case 6:
            textInfo = ( NSLocalizedString("FIREWORKS_TITLE",comment: "") , NSLocalizedString("FIREWORKS",comment: ""))
        case 7:
            textInfo = ( NSLocalizedString("ILLUMINATION_TITLE",comment: "") , NSLocalizedString("ILLUMINATION",comment: ""))
        default:
            errorLog("\(number)");
        }
        
        return textInfo
    }
    
    /// 撮影モードのサンプル画像
    ///
    /// - Parameter number: 選択番号
    /// - Returns: 画像ファイル名
    func getSampleImageName(number:Int) -> String? {
        var imageName:String?
        
        switch(number) {
        case 0:
            imageName = NSLocalizedString("SINGLE_IMG",comment: "")
        case 1:
            imageName = NSLocalizedString("CONTINUOUS_IMG",comment: "")
        case 2:
            imageName = NSLocalizedString("CLIPS_IMG",comment: "")
        case 3:
            imageName = NSLocalizedString("HDR_IMG",comment: "")
        case 4:
            imageName = NSLocalizedString("MOON_IMG",comment: "")
        case 5:
            imageName = NSLocalizedString("WATERFALL_IMG",comment: "")
        case 6:
            imageName = NSLocalizedString("FIREWORKS_IMG",comment: "")
        case 7:
            imageName = NSLocalizedString("ILLUMINATION_IMG",comment: "")
        default:
            errorLog("\(number)");
        }
        
        return imageName
    }
    
    // MARK: - userSetting
    /// ユーザーが選択した撮影モードの番号取得
    ///
    /// - Returns: 選択番号
    func getUserSelectNumber() -> Int {
        let settings = UserDefaults.standard
        let number = settings.integer(forKey: userSelectKey)
        
        return number
    }
    
    /// ユーザーが選択した撮影モードの番号を保持する
    ///
    /// - Parameter number: 選択番号
    func setUserSelectNumber(number:Int) {
        let settings = UserDefaults.standard
        settings.setValue(number, forKey: userSelectKey)
        settings.synchronize()
    }
    
    /// トーンコントール設定値取得
    ///
    /// - Returns: 値
    func getToneControl() -> ToneControl {
        var result:ToneControl = .zero
        //設定値取得
        let settings = UserDefaults.standard
        if let toneControlEnum:ToneControl = ToneControl(rawValue: settings.integer(forKey: userToneControlKey)) {
            result = toneControlEnum
        }
        return result
    }
    
    /// トーンコントール設定値設定
    ///
    /// - Parameter value: 値
    func setToneControl(value:ToneControl) {
        let settings = UserDefaults.standard
        settings.setValue(value.rawValue, forKey: userToneControlKey)
        settings.synchronize()
    }
    
    /// 露出補正値取得
    ///
    /// - Returns: 値
    func getExpRev() -> ExpRev {
        var result:ExpRev = .zero
        //設定値取得
        let settings = UserDefaults.standard
        if let expRevEnum:ExpRev = ExpRev(rawValue: settings.integer(forKey: userExprevKey)) {
            result = expRevEnum
        }
        return result
    }
    
    /// 露出補正値設定
    ///
    /// - Parameter value: 値
    func setExpRev(value:ExpRev) {
        let settings = UserDefaults.standard
        settings.setValue(value.rawValue, forKey: userExprevKey)
        settings.synchronize()
    }

    // MARK: - CameraKit Property
    /// カメラの設定パラメータ取得
    ///
    /// - Parameter number: 選択番号
    /// - Returns: パラメータ
    func getCameraKitProperty(number:Int) -> [String:String]? {
        
        isClipsMovie = false
        isHDRShooting = false
        isToneControl = false
        isExpRev = false
        
        var cameraKitProperty:[String:String]?
        
        //設定値取得
        
        let toneControlEnum = getToneControl()
        let expRevEnum = getExpRev()
        switch(number) {
        case 0:
            isToneControl = true
            cameraKitProperty = [
                "TAKEMODE":"<TAKEMODE/P>",
                "COLORTONE":"<COLORTONE/I_FINISH>",
                "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                "WB":"<WB/WB_AUTO>",
                "TONE_CONTROL_LOW":"<TONE_CONTROL_LOW/0>",
                "TONE_CONTROL_MIDDLE":"<TONE_CONTROL_MIDDLE/\(toneControlEnum.string())>",
                "TONE_CONTROL_HIGH":"<TONE_CONTROL_HIGH/0>",
                "AUTO_WB_DENKYU_COLORED_LEAVING":"<AUTO_WB_DENKYU_COLORED_LEAVING/ON>",
                "RECVIEW":"<RECVIEW/ON>",
            ]
        case 1:
            isToneControl = true
            cameraKitProperty = [
                "TAKEMODE":"<TAKEMODE/P>",
                "COLORTONE":"<COLORTONE/I_FINISH>",
                "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_CONTINUE>",
                "WB":"<WB/WB_AUTO>",
                "TONE_CONTROL_LOW":"<TONE_CONTROL_LOW/0>",
                "TONE_CONTROL_MIDDLE":"<TONE_CONTROL_MIDDLE/\(toneControlEnum.string())>",
                "TONE_CONTROL_HIGH":"<TONE_CONTROL_HIGH/0>",
                "AUTO_WB_DENKYU_COLORED_LEAVING":"<AUTO_WB_DENKYU_COLORED_LEAVING/ON>",
                "RECVIEW":"<RECVIEW/OFF>",
            ]

        case 2:
            isExpRev = true
            isClipsMovie = true
            cameraKitProperty = [
                "TAKEMODE":"<TAKEMODE/movie>",
                "QUALITY_MOVIE":"<QUALITY_MOVIE/QUALITY_MOVIE_SHORT_MOVIE>",
                "FULL_TIME_AF":"<FULL_TIME_AF/ON>",
                "EXPREV":"<EXPREV/\(expRevEnum.string())>",
            ]
        case 3:
            isHDRShooting = true
            isToneControl = true
            cameraKitProperty = [
                "TAKEMODE":"<TAKEMODE/A>",
                "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                "APERTURE":"<APERTURE/8.0>",
                //"RAW":"<RAW/ON>",
                "WB":"<WB/WB_AUTO>",
                "TONE_CONTROL_LOW":"<TONE_CONTROL_LOW/0>",
                "TONE_CONTROL_MIDDLE":"<TONE_CONTROL_MIDDLE/\(toneControlEnum.string())>",
                "TONE_CONTROL_HIGH":"<TONE_CONTROL_HIGH/0>",
                "AUTO_WB_DENKYU_COLORED_LEAVING":"<AUTO_WB_DENKYU_COLORED_LEAVING/ON>",
                "RECVIEW":"<RECVIEW/OFF>",
            ]
        case 4:
            let monthOld = getMonthOld()
            if (monthOld >= 13) && (monthOld <= 16) { //満月14.8
                cameraKitProperty = [
                    "TAKEMODE":"<TAKEMODE/M>",
                    "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                    "ISO":"<ISO/800>",
                    "SHUTTER":"<SHUTTER/1000>",
                    "APERTURE":"<APERTURE/8.0>",
                    "RECVIEW":"<RECVIEW/ON>",
                ]
            } else if ((monthOld >= 11) && (monthOld <= 13)) || ((monthOld >= 16) && (monthOld <= 18)) { //12.3,17.3
                cameraKitProperty = [
                    "TAKEMODE":"<TAKEMODE/M>",
                    "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                    "ISO":"<ISO/800>",
                    "SHUTTER":"<SHUTTER/500>",
                    "APERTURE":"<APERTURE/8.0>",
                    "RECVIEW":"<RECVIEW/ON>",
                ]
            } else if ((monthOld >= 8) && (monthOld <= 11)) || ((monthOld >= 18) && (monthOld <= 21)) { //9.9,19.8
                cameraKitProperty = [
                    "TAKEMODE":"<TAKEMODE/M>",
                    "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                    "ISO":"<ISO/800>",
                    "SHUTTER":"<SHUTTER/500>",
                    "APERTURE":"<APERTURE/6.3>",
                    "RECVIEW":"<RECVIEW/ON>",
                ]
            } else if ((monthOld >= 6) && (monthOld <= 8)) || ((monthOld >= 21) && (monthOld <= 23)) { //半月7.4,22.3
                cameraKitProperty = [
                    "TAKEMODE":"<TAKEMODE/M>",
                    "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                    "ISO":"<ISO/800>",
                    "SHUTTER":"<SHUTTER/250>",
                    "APERTURE":"<APERTURE/6.3>",
                    "RECVIEW":"<RECVIEW/ON>",
                ]
            } else if ((monthOld >= 3) && (monthOld <= 6)) || ((monthOld >= 23) && (monthOld <= 26)) { //4.9,24.8
                cameraKitProperty = [
                    "TAKEMODE":"<TAKEMODE/M>",
                    "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                    "ISO":"<ISO/1250>",
                    "SHUTTER":"<SHUTTER/250>",
                    "APERTURE":"<APERTURE/6.3>",
                    "RECVIEW":"<RECVIEW/ON>",
                ]
            } else if ((monthOld >= 0) && (monthOld <= 3)) || ((monthOld >= 26) && (monthOld <= 30)) { //三日月2.5,27.3
                cameraKitProperty = [
                    "TAKEMODE":"<TAKEMODE/M>",
                    "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                    "ISO":"<ISO/1600>",
                    "SHUTTER":"<SHUTTER/250>",
                    "APERTURE":"<APERTURE/6.3>",
                    "RECVIEW":"<RECVIEW/ON>",
                ]
            }
        case 5:
            cameraKitProperty = [
                "TAKEMODE":"<TAKEMODE/S>",
                "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                "ISO":"<ISO/200>",
                "SHUTTER":"<SHUTTER/1\">",
                //"FOCUS_STILL":"<FOCUS_STILL/FOCUS_SAF>",
                "RECVIEW":"<RECVIEW/ON>",
            ]
        case 6:
            isToneControl = true
            cameraKitProperty = [
                "TAKEMODE":"<TAKEMODE/M>",
                "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                "ISO":"<ISO/Low>",
                "SHUTTER":"<SHUTTER/4\">",
                "APERTURE":"<APERTURE/11>",
                "WB":"<WB/MWB_LAMP>",
                //"FOCUS_STILL":"<FOCUS_STILL/FOCUS_SAF>",
                "TONE_CONTROL_LOW":"<TONE_CONTROL_LOW/0>",
                "TONE_CONTROL_MIDDLE":"<TONE_CONTROL_MIDDLE/\(toneControlEnum.string())>",
                "TONE_CONTROL_HIGH":"<TONE_CONTROL_HIGH/0>",
                "RECVIEW":"<RECVIEW/ON>",
            ]
        case 7:
            isToneControl = true
            cameraKitProperty = [
                "TAKEMODE":"<TAKEMODE/P>",
                "EXPREV":"<EXPREV/+0.7>",
                "COLORTONE":"<COLORTONE/FANTASIC_FOCUS>",
                "ART_EFFECT_HYBRID_FANTASIC_FOCUS":"<ART_EFFECT_HYBRID_FANTASIC_FOCUS/STARLIGHT>",
                "TAKE_DRIVE":"<TAKE_DRIVE/DRIVE_NORMAL>",
                "WB":"<WB/WB_AUTO>",
                "TONE_CONTROL_LOW":"<TONE_CONTROL_LOW/0>",
                "TONE_CONTROL_MIDDLE":"<TONE_CONTROL_MIDDLE/\(toneControlEnum.string())>",
                "TONE_CONTROL_HIGH":"<TONE_CONTROL_HIGH/0>",
                "AUTO_WB_DENKYU_COLORED_LEAVING":"<AUTO_WB_DENKYU_COLORED_LEAVING/ON>",
                "RECVIEW":"<RECVIEW/ON>",
            ]
        default:
            errorLog("\(number)");
        }
        
        return cameraKitProperty
    }
    
    // MARK: - Private
    private func getMonthOld() -> Int {
        var monthOld:Int = 0
        let calendar = Calendar(identifier: .gregorian)
        let yearComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        if let year = yearComponents.year , let month = yearComponents.month , let day = yearComponents.day {
            //(((YYYY-2009) %19)×11+MM+DD) %30
            monthOld = (((year - 2009) % 19) * 11 + month + day ) % 30
            if month <= 2 {
                // 1月と2月の月齢については、上記計算値に 2 を加える
                monthOld += 2
            }
            if monthOld > 30 {
                // 30超えると想定外になるため30にクリップする
                monthOld = 30
            }

        }
        return monthOld
    }
    
    
}

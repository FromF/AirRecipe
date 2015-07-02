//
//  ViewController.swift
//  AirRecipe
//
//  Created by Fuji on 2015/05/26.
//  Copyright (c) 2015年 FromF. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController , UIScrollViewDelegate {
    @IBOutlet weak var CatalogScrollView: UIScrollView!
    @IBOutlet weak var DetailTextView: UITextView!
    @IBOutlet weak var CatalogPageControl: UIPageControl!
    //AppDelegate instance
    var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    //CoreLocation Serivce
    var locationManager = CLLocationManager()
    //
    var CatalogImageViews:AnyObject!
    let CatalogPageMax:NSInteger = 7
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        var defaultvalue : NSDictionary = [appDelegate.CatalogSelectNumber : 0]
        appDelegate.defaults.registerDefaults(defaultvalue as [NSObject : AnyObject])
        
        CatalogPageControl.numberOfPages = CatalogPageMax
        CatalogScrollView.delegate = self
        
        // 位置情報へのアクセスを要求する
        locationManager.requestAlwaysAuthorization()  //GPS無効
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //
        let CatalogScrollViewWith : CGFloat = CatalogScrollView.frame.size.width
        let CatalogScrollViewHeight : CGFloat = CatalogScrollView.frame.size.height
        
        var contentView:UIView = UIView(frame: CGRectMake( 0, 0, CatalogScrollViewWith * CGFloat(CatalogPageMax), CatalogScrollViewHeight))
        
        for (var i:CGFloat = 0;i < CGFloat(CatalogPageMax) ; i++) {
            var subContentView:UIImageView = UIImageView(frame: CGRectMake( CatalogScrollViewWith * i, 0, CatalogScrollViewWith, CatalogScrollViewHeight))
            
            var filename = getImageFilename(NSInteger(i))
            subContentView.image = UIImage(named: filename)
            subContentView.backgroundColor = UIColor.grayColor()
            subContentView.contentMode = UIViewContentMode.ScaleAspectFill
            subContentView.clipsToBounds = true
            contentView.addSubview(subContentView)
            //CatalogImageViews.addObject(subContentView)
        }
        CatalogScrollView.contentSize = contentView.frame.size
        CatalogScrollView.addSubview(contentView)
        //設定呼び出し
        let currentPage = appDelegate.defaults.objectForKey(appDelegate.CatalogSelectNumber) as! NSInteger
        //カレント位置設定
        self.CatalogPageControl.currentPage = currentPage;
        CatalogScrollView.contentOffset = CGPointMake(CatalogScrollViewWith * CGFloat(currentPage),0)
        //println("framesize = \(self.CatalogScrollView.frame.size) contentOffset = \(self.CatalogScrollView.contentOffset)")
        //テキスト内容更新
        updateDetailTextView()
    }
    
    // MARK: - ScrollView Delegate
    func scrollViewDidScroll(scrollview: UIScrollView) {
        //println("framesize = \(self.CatalogScrollView.frame.size) contentOffset = \(self.CatalogScrollView.contentOffset)")
        var pageWidth : CGFloat = self.CatalogScrollView.frame.size.width
        var fractionalPage : Double = Double(self.CatalogScrollView.contentOffset.x / pageWidth)
        var page : NSInteger = lround(fractionalPage)
        self.CatalogPageControl.currentPage = page;
        updateDetailTextView()
        //設定保持
        appDelegate.defaults.setObject(page, forKey:appDelegate.CatalogSelectNumber)
        appDelegate.defaults.synchronize()
    }

    // MARK: - DetailTextViewUpdate
    func updateDetailTextView() {
        var stringTitle:String = ""
        var stringDetail:String = ""
        
        //各種設定に応じた説明文を選択
        switch(self.CatalogPageControl.currentPage) {
            case 0:
                stringTitle  = NSLocalizedString("SINGLE_TITLE",comment: "")
                stringDetail = NSLocalizedString("SINGLE",comment: "")
            case 1:
                stringTitle  = NSLocalizedString("CONTINUOUS_TITLE",comment: "")
                stringDetail = NSLocalizedString("CONTINUOUS",comment: "")
            case 2:
                stringTitle  = NSLocalizedString("CLIPS_TITLE",comment: "")
                stringDetail = NSLocalizedString("CLIPS",comment: "")
            case 3:
                stringTitle  = NSLocalizedString("HDR_TITLE",comment: "")
                stringDetail = NSLocalizedString("HDR",comment: "")
            case 4:
                stringTitle  = NSLocalizedString("MOON_TITLE",comment: "")
                stringDetail = NSLocalizedString("MOON",comment: "")
            case 5:
                stringTitle  = NSLocalizedString("WATERFALL_TITLE",comment: "")
                stringDetail = NSLocalizedString("WATERFALL",comment: "")
            case 6:
                stringTitle  = NSLocalizedString("FIREWORKS_TITLE",comment: "")
                stringDetail = NSLocalizedString("FIREWORKS",comment: "")
            default:
                self.DetailTextView.text = "---"
        }
        //アンダーバー付き太字で文字を生成する
        var attrStringTitle = NSAttributedString(string: stringTitle, attributes:[NSUnderlineStyleAttributeName : 1 , NSFontAttributeName:UIFont.boldSystemFontOfSize(12.0)])
        //通常の文字を生成する
        var attrStringDetail = NSAttributedString(string: "\n\(stringDetail)", attributes:[NSUnderlineStyleAttributeName : 0])
        //生成した文字を結合する
        var mutableAttributedString = NSMutableAttributedString()
        mutableAttributedString.appendAttributedString(attrStringTitle)
        mutableAttributedString.appendAttributedString(attrStringDetail)
        //TextViewに結合した文字列をセットする
        self.DetailTextView.attributedText = mutableAttributedString
    }
}


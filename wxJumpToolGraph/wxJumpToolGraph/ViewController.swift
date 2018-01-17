//
//  ViewController.swift
//  wxJumpToolGraph
//
//  Created by 李铁柱 on 2018/1/16.
//  Copyright © 2018年 李铁柱. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    var tool = wxJumpTool.init()
    
    var imageView: UIImageView?
    var chessPointView: UIView?
    var nextPointView: UIView?
    var controlBtn: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        guard tool.initSession() != false else {
            print("init session fail")
            return
        }
        
        tool.chessImage = UIImage.init(named: "chessImage_1242.png")?.cgImage!
        tool.setOutInfoBlock { (image, chessPoint, nextPoint) in
            /// 使用跟手机匹配的模拟器 位置才对
            self.imageView?.image = UIImage.init(cgImage: image)
            self.chessPointView?.center = self.scalePoint(point: chessPoint)
            self.nextPointView?.center = self.scalePoint(point: nextPoint)
        }
        
        imageView = UIImageView.init(frame: self.view.bounds)
        self.view.addSubview(imageView!);
        
        chessPointView = UIView.init(frame: CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: 5, height: 5)))
        chessPointView?.backgroundColor = UIColor.red
        self.view.addSubview(chessPointView!)
        
        nextPointView = UIView.init(frame: CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: 5, height: 5)))
        nextPointView?.backgroundColor = UIColor.blue
        self.view.addSubview(nextPointView!)
        
        controlBtn = UIButton.init(type: UIButtonType.custom)
        controlBtn?.frame = CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: self.view.frame.size.width, height: 50))
        controlBtn?.setTitle("Start", for: UIControlState.normal)
        controlBtn?.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.5)
        controlBtn?.addTarget(self, action: #selector(controlBtnClick), for: UIControlEvents.touchUpInside)
        self.view.addSubview(controlBtn!)
        
//        tool.parseGameImageData(imageData: try! Data.init(contentsOf: URL.init(fileURLWithPath: "/Users/litiezhu/Documents/output/1516123271.53487.png")), debug: true)
    }
    
    var isRunning: Bool = false
    @objc func controlBtnClick() {
        isRunning = !isRunning
        if isRunning {
            tool.startAlwaysJump()
            controlBtn?.setTitle("Stop", for: UIControlState.normal)
        } else {
            tool.stop()
            controlBtn?.setTitle("Start", for: UIControlState.normal)
        }
    }
 
    func scalePoint(point: CGPoint) -> CGPoint {
        return CGPoint.init(x: point.x / UIScreen.main.scale, y: point.y / UIScreen.main.scale)
    }
    
}


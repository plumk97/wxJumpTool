//
//  wxJumoTool.swift
//  
//
//  Created by 李铁柱 on 2018/1/16.
//

import Foundation
import CoreGraphics


/// 游戏图片、棋子坐标和下一个位置坐标
typealias wxJumpToolOutInfoBlock = (CGImage, CGPoint, CGPoint) -> Void
public class wxJumpTool : NSObject {
    
    /// WDA usb 接口
    let baseUrl = "http://127.0.0.1:8100/"
    var sessionId: String?
    
    struct wxJumpToolConfig {
        
        /// 棋子偏移 让坐标在棋子底部中心
        var chessOffset: CGPoint = CGPoint.zero
        var nextOffset: CGPoint = CGPoint.zero
        
        /// 距离计算 除数
        var distanceDivisor:Float = 0
        
        /// 扫描下个坐标跳过顶部高度
        var scanJumpHeight = 0
        /// 扫描下个坐标 x距离棋子之内都跳过 防止棋子比下一个高，音符等
        var scanSpaceChess = 0
    }
    var useConfig = wxJumpToolConfig.init()
    
    /// 根据宽度更新配置信息
    ///
    /// - Parameter width:
    func renewUseConfig(width: Int) {
        useConfig.chessOffset.x = 5
        useConfig.chessOffset.y = 6
        switch width {
        case 750: // 4.7屏幕
            useConfig.nextOffset.x = 10
            useConfig.nextOffset.y = 50
            
            useConfig.distanceDivisor = 520.0
            useConfig.scanJumpHeight = 300
            useConfig.scanSpaceChess = 50
            break
        case 1242: // 5.5屏幕
            useConfig.nextOffset.x = 16
            useConfig.nextOffset.y = 83
            
            useConfig.distanceDivisor = 861.0
            useConfig.scanJumpHeight = 500
            useConfig.scanSpaceChess = 100
            break
        default: break
            
        }
    }
    private func sendRequest(url:String) -> Dictionary<String, Any>? {
        
        let completeUrl = baseUrl + url
        let data = try? Data.init(contentsOf: URL.init(string: completeUrl)!)
        guard data != nil else {
            print("send request fail")
            return nil
        }
        
        let dict:Dictionary<String, Any>? = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! Dictionary<String, Any>
        
        guard dict != nil else {
            print("response data error")
            return nil
        }
        return dict
    }
    
    /// 获取sessionId
     func initSession() -> Bool {
        sessionId = sendRequest(url: "")?["sessionId"] as? String
        return sessionId != nil
    }
    
    private var isRunning: Bool = false
     func startAlwaysJump() {
        guard isRunning == false else {
            return
        }
        isRunning = true
        onceJump()
    }
    
     func stop() {
        isRunning = false
    }
    
    var outInfoBlock: wxJumpToolOutInfoBlock?
    /// 设置输出信息
    ///
    /// - Parameter b:
     func setOutInfoBlock(b: @escaping wxJumpToolOutInfoBlock)  {
        outInfoBlock = b
    }
    
    
    /// 棋子部分截图
    var chessImage:CGImage?
    
    /// 跳一次
    @objc func onceJump() {
        
        guard chessImage != nil else {
            print("chessImage for nil")
            return
        }
        
        let dict = sendRequest(url: "screenshot")
        guard dict != nil else {
            print("jump fail")
            return
        }
        let imageData = Data.init(base64Encoded: (dict!["value"] as! String), options: Data.Base64DecodingOptions.ignoreUnknownCharacters)
        
        guard imageData != nil else {
            print("jump fail")
            return
        }
        parseGameImageData(imageData: imageData!, debug: false)
    }
    
    
    /// 解析游戏截图 计算位置距离
    ///
    /// - Parameters:
    ///   - imageData: 游戏截图
    ///   - debug: 是否调试 单独调用这个方法测试位置是否准确
     func parseGameImageData(imageData:Data, debug:Bool ) {
        
        if !debug {
            /// 可以把图片输出看是在哪个图片掉下去 然后用调试模式分析
           //try! imageData.write(to: URL.init(fileURLWithPath: "/Users/litiezhu/Documents/output/\(NSDate.init().timeIntervalSince1970).png"))
        }
        
        var cfData: CFData?
        imageData.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) in
            cfData = CFDataCreate(kCFAllocatorDefault, ptr, imageData.count)
        }
        
        guard cfData != nil else {
            print("jump fail")
            return
        }
        
        let cgImage = CGImage.init(pngDataProviderSource: CGDataProvider.init(data: cfData!)!, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        
        guard cgImage != nil else {
            print("jump fail")
            return
        }
        renewUseConfig(width: cgImage!.width)

        var chessPoint = imageContainOtherImage_Gray(image: cgImage!, otherImage: chessImage!, range: 5)
        if (chessPoint.x < 0) {
            for i in 2 ... 9 {
                chessPoint = imageContainOtherImage_Gray(image: cgImage!, otherImage: chessImage!, range: 5 * i)
                if chessPoint.x > 0 {
                    break
                }
            }
        }
        
        guard chessPoint.x > 0 else {
            print("not found chess")
            return
        }
        chessPoint.x = chessPoint.x + CGFloat((chessImage?.width)! / 2) + useConfig.chessOffset.x
        chessPoint.y = chessPoint.y + CGFloat((chessImage?.height)!) + useConfig.chessOffset.y
        
        var nextPoint = wxJumpNextPosition(image: cgImage!, chessPoint: chessPoint)
        if chessPoint.x > CGFloat((cgImage?.width)!) / 2 {
            nextPoint.x = nextPoint.x - useConfig.nextOffset.x
        } else {
            nextPoint.x = nextPoint.x + useConfig.nextOffset.x
        }
        nextPoint.y = nextPoint.y + useConfig.nextOffset.y
        
        if self.outInfoBlock != nil {
            self.outInfoBlock!(cgImage!, chessPoint, nextPoint)
        }
        
        if debug {
            return
        }
        
        let distance = abs(sqrt(pow(abs((nextPoint.x - chessPoint.x)), 2) + pow(abs((nextPoint.y - chessPoint.y)), 2)))
        
        let sec = Float(distance) / useConfig.distanceDivisor
        print(sec)
        
        var request = URLRequest.init(url: URL.init(string: baseUrl + "session/\(sessionId!)/wda/touchAndHold")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
        let params = ["x": 200 + arc4random() % 100, "y": 400 + arc4random() % 100, "duration": sec] as [String : Any]
        request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions.prettyPrinted)
        
        /// 控制台程序 URLSession 返回block里面不知道怎么切到主线程 所以不检查返回值
        if NSClassFromString("UIView") == nil {
            URLSession.shared.dataTask(with: request).resume();
            return
        }
        
        URLSession.shared.dataTask(with: request) { (data, res, err) in
            
            if err == nil {
                let dict:Dictionary<String, Any>? = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! Dictionary<String, Any>
                let status = dict!["status"] as! Int
                if status != 0 {
                    print("touchAndHold fail")
                }
            } else {
                print(err!)
            }
            
            if self.isRunning {
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + CFTimeInterval(sec) + CFTimeInterval(arc4random() % 1) + CFTimeInterval(1.25), execute: {
                    self.onceJump()
                })
            }
        }.resume()
    }
    
    
    /// 获取下一个位置
    ///
    /// - Parameter image:
    /// - Returns:
    func wxJumpNextPosition(image: CGImage, chessPoint: CGPoint) -> CGPoint {
        
        let imageTuples = makeRGBBitmapContext(image: image)
        
        var start = CGPoint.zero
        var end = CGPoint.zero
        var center = CGPoint.zero
        var backgroundColor:UInt16 = 0
    
        
        for y in useConfig.scanJumpHeight ..< imageTuples.ctx.height {
            for x in 0 ..< imageTuples.ctx.bytesPerRow / 4 {
                
                if CGFloat(x + useConfig.scanSpaceChess) >= chessPoint.x && CGFloat(x - useConfig.scanSpaceChess) <= chessPoint.x {
                    continue
                }
                
                let offset = y * imageTuples.ctx.bytesPerRow + x * 4
                let r = imageTuples.dataPointer.advanced(by: offset).pointee
                let g = imageTuples.dataPointer.advanced(by: offset + 1).pointee
                let b = imageTuples.dataPointer.advanced(by: offset + 2).pointee
                
                var sum: UInt16 = UInt16(r) + UInt16(g) + UInt16(b)
                if (backgroundColor == 0) {
                    backgroundColor = sum
                }
                
                let ratio = CGFloat(sum) / CGFloat(backgroundColor)
                let range:CGFloat = 0.055555
                if ratio > (1.0 - range) && ratio < (1.0 + range) {
                    sum = 0
                    imageTuples.dataPointer.advanced(by: offset).pointee = 0
                    imageTuples.dataPointer.advanced(by: offset + 1).pointee = 0
                    imageTuples.dataPointer.advanced(by: offset + 2).pointee = 0
                    imageTuples.dataPointer.advanced(by: offset + 3).pointee = 255
                }
                
                if sum > 0 {
                    if start.equalTo(CGPoint.zero) {
                        start.x = CGFloat(x)
                        start.y = CGFloat(y)
                    }
                    
                    if end.equalTo(CGPoint.zero) {
                        end.x = CGFloat(x)
                        end.y = CGFloat(y)
                    } else {
                        end.x = max(end.x, CGFloat(x))
                    }
                }
            }
            if !start.equalTo(CGPoint.zero) {
                center.y = start.y
                center.x = (start.x + (end.x - start.x) / 2)
                break
            }
        }
        
        releaseContext(context: imageTuples.ctx, dataPointer: imageTuples.dataPointer)
        return center
    }
}

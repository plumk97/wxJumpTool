//
//  main.swift
//  wxJumpToolConsole
//
//  Created by 李铁柱 on 2018/1/16.
//  Copyright © 2018年 李铁柱. All rights reserved.
//

import Foundation


var tool = wxJumpTool.init()
tool.chessImage = CGImage.init(pngDataProviderSource: CGDataProvider.init(filename: "<#棋子文件截图路径#>")!, decode: nil, shouldInterpolate: false, intent: .defaultIntent)

while true {
    
    print("输入S开始，其他任意退出")
    let c = getchar()
    if c != 10 {
        getchar()
    }
    
    if c == 98 || c == 115 {
        guard tool.initSession() else {
            print("init session fail")
            break
        }
        /// 一直跳
        while true {
            tool.onceJump()
            /// 因为没有判断返回值 一直发送命令 时间太快会出错
            Thread.sleep(forTimeInterval: CFTimeInterval(arc4random() % 1) + CFTimeInterval(2.25))
        }
    } else {
        break
    }
}

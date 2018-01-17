//
//  ImageFind.swift
//  wxJumpTool
//
//  Created by 李铁柱 on 2018/1/16.
//  Copyright © 2018年 李铁柱. All rights reserved.
//

import Foundation
import CoreGraphics

/// 创建RGBA位图环境
///
/// - Parameter image:
/// - Returns:
func makeRGBBitmapContext(image: CGImage) -> (ctx: CGContext, dataPointer: UnsafeMutablePointer<UInt8>, dataLength: UInt64) {
    
    let imageRect = CGRect(x: 0, y: 0, width: Int(CGFloat(image.width) * 1), height: Int(CGFloat(image.height) * 1))
    
    let data: UnsafeMutableRawPointer = UnsafeMutableRawPointer.allocate(bytes: Int(imageRect.size.width * imageRect.size.height * 4), alignedTo: 0)
    data.initializeMemory(as: UInt8.self, to: 0)
    let mutablePointer = data.assumingMemoryBound(to: UInt8.self)
    
    let context = CGContext.init(data: data, width: Int(imageRect.size.width), height: Int(imageRect.size.height), bitsPerComponent: 8, bytesPerRow: Int(imageRect.size.width) * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    context?.draw(image, in: imageRect)
    
    return (context!, mutablePointer, UInt64(imageRect.size.width * imageRect.size.height) * 4)
}

/// 创建灰度位图环境
///
/// - Parameter image:
/// - Returns:
func makeGrayBitmapContext(image: CGImage) -> (ctx: CGContext, dataPointer: UnsafeMutablePointer<UInt8>, dataLength: UInt64) {
    
    let imageRect = CGRect(x: 0, y: 0, width: Int(CGFloat(image.width) * 1), height: Int(CGFloat(image.height) * 1))
    
    let data: UnsafeMutableRawPointer = UnsafeMutableRawPointer.allocate(bytes: Int(imageRect.size.width * imageRect.size.height), alignedTo: 0)
    data.initializeMemory(as: UInt8.self, to: 0)
    let mutablePointer = data.assumingMemoryBound(to: UInt8.self)
    
    let context = CGContext.init(data: data, width: Int(imageRect.size.width), height: Int(imageRect.size.height), bitsPerComponent: 8, bytesPerRow: Int(imageRect.size.width), space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
    context?.draw(image, in: imageRect)
    
    return (context!, mutablePointer, UInt64(imageRect.size.width * imageRect.size.height))
}

/// 释放图片环境
///
/// - Parameters:
///   - context:
///   - dataPointer:
func releaseContext(context: CGContext, dataPointer: UnsafeMutablePointer<UInt8>) -> Void {
    dataPointer.deinitialize()
    context.data?.deallocate(bytes: (context.width) * (context.height), alignedTo: 0)
}

/// 查找一张图片在另外一张图片的位置_灰度模式查找
///
/// - Parameters:
///   - image:
///   - otherImage:
///   - range: 误差
/// - Returns: 如果找到则返回 otherImage 在 image 的左上角坐标
func imageContainOtherImage_Gray(image: CGImage, otherImage: CGImage, range: Int) -> CGPoint {
    
    let imageTuples = makeGrayBitmapContext(image: image)
    let otherImageTuples = makeGrayBitmapContext(image: otherImage)
    
    /// 查找图片所在位置 误差20
    ///
    /// - Parameters:
    ///   - imageRow: 在 image 的哪一行查找
    ///   - findRow: 查找 otherImage 的哪一行
    /// - Returns: 如果没有找到 CGPoint 值为 -1， 如果找到则左边为 otherImage 在 image 的左下角坐标
    func equalFindRow(imageRow: Int, findRow: Int) -> CGPoint {
        
        var isFind = false
        var point = CGPoint(x: -1, y: -1)
        
        for x in 0 ... imageTuples.ctx.bytesPerRow - otherImageTuples.ctx.bytesPerRow {
            
            var isEqual = true
            for z in 0 ..< otherImageTuples.ctx.bytesPerRow / 2 {
                let p1 = imageTuples.dataPointer.advanced(by: imageRow * imageTuples.ctx.bytesPerRow + x + z * 2).pointee
                let p2 = otherImageTuples.dataPointer.advanced(by: findRow * otherImageTuples.ctx.bytesPerRow + z * 2).pointee
                if (abs(Int(p1) - Int(p2)) > range) {
                    isEqual = false
                    break
                }
            }
            
            if isEqual {
                /**
                 这里得出的左边是左下角左边
                 y需要加1 如果图片高度50，分行找最后一行就是在49
                 */
                point.x = CGFloat(x)
                point.y = CGFloat(imageRow + 1)
                isFind = true
                break
            }
        }
        
        if findRow >= otherImageTuples.ctx.height - 1 || imageRow >= imageTuples.ctx.height - 1 {
            return point
        }
        
        if isFind {
            return equalFindRow(imageRow: imageRow + 1, findRow: findRow + 1)
        } else {
            if findRow == 0 {
                return equalFindRow(imageRow: imageRow + 1, findRow: 0)
            } else {
                return equalFindRow(imageRow: imageRow, findRow: 0)
            }
        }
    }
    
    var point = equalFindRow(imageRow: 0, findRow: 0)
    point.y = point.y - CGFloat(otherImageTuples.ctx.height)
    
    releaseContext(context: imageTuples.ctx, dataPointer: imageTuples.dataPointer)
    releaseContext(context: otherImageTuples.ctx, dataPointer: otherImageTuples.dataPointer)
    
    return point
}

/// 查找一张图片在另外一张图片的位置_RGB模式查找
///
/// - Parameters:
///   - image:
///   - otherImage:
/// - Returns: 如果找到则返回 otherImage 在 image 的左上角坐标
func imageContainOtherImage_RGB(image: CGImage, otherImage: CGImage, range: Int) -> CGPoint {
    
    let imageTuples = makeRGBBitmapContext(image: image)
    let otherImageTuples = makeRGBBitmapContext(image: otherImage)
    
    /// 查找图片所在位置 颜色误差40
    ///
    /// - Parameters:
    ///   - imageRow: 在 image 的哪一行查找
    ///   - findRow: 查找 otherImage 的哪一行
    /// - Returns: 如果没有找到 CGPoint 值为 -1， 如果找到则左边为 otherImage 在 image 的左下角坐标
    func equalFindRow(imageRow: Int, findRow: Int) -> CGPoint {
        
        var isFind = false
        var point = CGPoint(x: -1, y: -1)
        
        for x in 0 ... (imageTuples.ctx.bytesPerRow - otherImageTuples.ctx.bytesPerRow) / 4 {
            
            var isEqual = true
            for z in 0 ..< otherImageTuples.ctx.bytesPerRow / 4 {
                
                
                let offset1 = imageRow * imageTuples.ctx.bytesPerRow + x * 4 + z * 4
                let offset2 = findRow * otherImageTuples.ctx.bytesPerRow + z * 4
                
                let r1 = imageTuples.dataPointer.advanced(by: offset1).pointee
                let g1 = imageTuples.dataPointer.advanced(by: offset1 + 1).pointee
                let b1 = imageTuples.dataPointer.advanced(by: offset1 + 2).pointee
//                let a1 = imageTuples.dataPointer.advanced(by: offset1 + 3).pointee
                
                
                let r2 = otherImageTuples.dataPointer.advanced(by: offset2).pointee
                let g2 = otherImageTuples.dataPointer.advanced(by: offset2 + 1).pointee
                let b2 = otherImageTuples.dataPointer.advanced(by: offset2 + 2).pointee
//                let a2 = otherImageTuples.dataPointer.advanced(by: offset2 + 3).pointee
                
                
                let colorSum1 = UInt16(r1) + UInt16(g1) + UInt16(b1)
                let colorSum2 = UInt16(r2) + UInt16(g2) + UInt16(b2)
                
                if (abs(Int(colorSum1) - Int(colorSum2)) > range) {
                    isEqual = false
                    break;
                }
            }
            
            if isEqual {
                /**
                 这里得出的左边是左下角左边
                 y需要加1 如果图片高度50，分行找最后一行就是在49
                 */
                point.x = CGFloat(x)
                point.y = CGFloat(imageRow + 1)
                isFind = true
                break
            }
        }
        
        if findRow >= otherImageTuples.ctx.height - 1 || imageRow >= imageTuples.ctx.height - 1 {
            return point
        }
        
        if isFind {
            return equalFindRow(imageRow: imageRow + 1, findRow: findRow + 1)
        } else {
            if findRow == 0 {
                return equalFindRow(imageRow: imageRow + 1, findRow: 0)
            } else {
                return equalFindRow(imageRow: imageRow, findRow: 0)
            }
        }
    }
    
    var point = equalFindRow(imageRow: 0, findRow: 0)
    point.y = point.y - CGFloat(otherImageTuples.ctx.height)
    
    releaseContext(context: imageTuples.ctx, dataPointer: imageTuples.dataPointer)
    releaseContext(context: otherImageTuples.ctx, dataPointer: otherImageTuples.dataPointer)
    
    return point
}

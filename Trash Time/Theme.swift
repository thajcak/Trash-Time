//
//  Theme.swift
//  Trash Time
//
//  Created by Thomas Hajcak on 4/17/15.
//  Copyright (c) 2015 Simple Ink. All rights reserved.
//

import UIKit

public class Theme {
    
    public enum ImageColor {
        case White
        case Blue
        case Green
        case Gray
        
        public func color() -> UIColor {
            switch (self) {
            case .White: return UIColor.whiteColor()
            case .Blue: return UIColor(red: CGFloat(49.0/255.0), green: CGFloat(130.0/255.0), blue: CGFloat(217.0/255.0), alpha: 1)
            case .Green: return UIColor(red: CGFloat(49.0/255.0), green: CGFloat(163.0/255.0), blue: CGFloat(67.0/255.0), alpha: 1)
            case .Gray: return UIColor(white: 0.35, alpha: 1.0)
            }
        }
    }

    public static func fillImage(image: UIImage, color: ImageColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, UIScreen.mainScreen().scale)
        let context = UIGraphicsGetCurrentContext()
        color.color().setFill()
        
        CGContextTranslateCTM(context, 0, image.size.height)
        CGContextScaleCTM(context, 1, -1)
        
        CGContextSetBlendMode(context, kCGBlendModeColorBurn)
        let rect = CGRectMake(0, 0, image.size.width, image.size.height)
        CGContextDrawImage(context, rect, image.CGImage)
        
        CGContextSetBlendMode(context, kCGBlendModeSourceIn)
        CGContextAddRect(context, rect)
        CGContextDrawPath(context, kCGPathFill)
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage
    }
}
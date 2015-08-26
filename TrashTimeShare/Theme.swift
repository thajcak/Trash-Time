//
//  Theme.swift
//  Trash Time
//
//  Created by Thomas Hajcak on 4/17/15.
//  Copyright (c) 2015 Simple Ink. All rights reserved.
//

import UIKit

public class Theme {
    
    public enum Color {
        case White
        case Blue
        case Green
        case Gray
        case Black
        
        public func color() -> UIColor {
            switch (self) {
            case .White: return UIColor.whiteColor()
            case .Blue: return UIColor(red: CGFloat(49.0/255.0), green: CGFloat(130.0/255.0), blue: CGFloat(217.0/255.0), alpha: 1)
            case .Green: return UIColor(red: CGFloat(49.0/255.0), green: CGFloat(163.0/255.0), blue: CGFloat(67.0/255.0), alpha: 1)
            case .Gray: return UIColor(white: 0.35, alpha: 1.0)
            case .Black: return UIColor.blackColor()
            }
        }
    }

    public static func fillImage(image: UIImage, color: Color) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, UIScreen.mainScreen().scale)
        let context = UIGraphicsGetCurrentContext()
        color.color().setFill()
        
        CGContextTranslateCTM(context, 0, image.size.height)
        CGContextScaleCTM(context, 1, -1)
        
        CGContextSetBlendMode(context, CGBlendMode.ColorBurn)
        let rect = CGRectMake(0, 0, image.size.width, image.size.height)
        CGContextDrawImage(context, rect, image.CGImage)
        
        CGContextSetBlendMode(context, CGBlendMode.SourceIn)
        CGContextAddRect(context, rect)
        CGContextDrawPath(context, CGPathDrawingMode.Fill)
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage
    }
}
//
//  CustomXAxisRenderer.swift
//  QueuedMusic-iPadAdmin
//
//  Created by Micky on 6/9/17.
//  Copyright © 2017 Red Shepard LLC. All rights reserved.
//

import UIKit
import Charts
import Foundation
import CoreGraphics

class CustomXAxisRenderer: XAxisRenderer {
    
    override func drawLabels(context: CGContext, pos: CGFloat, anchor: CGPoint)
    {
        guard
            let xAxis = self.axis as? XAxis,
            let viewPortHandler = self.viewPortHandler,
            let transformer = self.transformer
            else { return }
        
        #if os(OSX)
            let paraStyle = NSParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
        #else
            let paraStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        #endif
        paraStyle.alignment = .center
        
        let labelAttrs = [NSFontAttributeName: xAxis.labelFont,
                          NSForegroundColorAttributeName: xAxis.labelTextColor,
                          NSParagraphStyleAttributeName: paraStyle] as [String : NSObject]
        let labelRotationAngleRadians = xAxis.labelRotationAngle * CGFloat(M_PI / 180.0) //ChartUtils.Math.FDEG2RAD
        
        let centeringEnabled = xAxis.isCenterAxisLabelsEnabled
        
        let valueToPixelMatrix = transformer.valueToPixelMatrix
        
        var position = CGPoint(x: 0.0, y: 0.0)
        
        var labelMaxSize = CGSize()
        
        if xAxis.isWordWrapEnabled
        {
            labelMaxSize.width = xAxis.wordWrapWidthPercent * valueToPixelMatrix.a
        }
        
        let entries = xAxis.entries
        
        for i in stride(from: 0, to: entries.count, by: 1)
        {
            if centeringEnabled
            {
                position.x = CGFloat(xAxis.centeredEntries[i])
            }
            else
            {
                position.x = CGFloat(entries[i])
            }
            
            position.y = 0.0
            position = position.applying(valueToPixelMatrix)
            
            if viewPortHandler.isInBoundsX(position.x)
            {
                let date = Date(timeIntervalSince1970: TimeInterval(Int(Date().timeIntervalSince1970) - (6 - i) * 86400))
                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = TimeZone(abbreviation: "GMT") //Set timezone that you want
                dateFormatter.locale = NSLocale.current
                dateFormatter.dateFormat = "EE" //Specify your format that you want
                let label = dateFormatter.string(from: date)
                
                let labelns = label as NSString
                
                if xAxis.isAvoidFirstLastClippingEnabled
                {
                    // avoid clipping of the last
                    if i == xAxis.entryCount - 1 && xAxis.entryCount > 1
                    {
                        let width = labelns.boundingRect(with: labelMaxSize, options: .usesLineFragmentOrigin, attributes: labelAttrs, context: nil).size.width
                        
                        if width > viewPortHandler.offsetRight * 2.0
                            && position.x + width > viewPortHandler.chartWidth
                        {
                            position.x -= width / 2.0
                        }
                    }
                    else if i == 0
                    { // avoid clipping of the first
                        let width = labelns.boundingRect(with: labelMaxSize, options: .usesLineFragmentOrigin, attributes: labelAttrs, context: nil).size.width
                        position.x += width / 2.0
                    }
                }
                
                drawLabel(context: context,
                          formattedLabel: label,
                          x: position.x,
                          y: pos,
                          attributes: labelAttrs,
                          constrainedToSize: labelMaxSize,
                          anchor: anchor,
                          angleRadians: labelRotationAngleRadians)
            }
        }
    }
}

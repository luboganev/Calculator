//
//  GraphView.swift
//  Calculator
//
//  Created by Lyubomir Ganev on 22/02/15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

protocol GraphViewDataSource: class {
    func evaluatedValue(sender: GraphView, xValue: Double) -> Double?
}

@IBDesignable
class GraphView: UIView {

    @IBInspectable
    var scale: CGFloat {
        set {
            axisScale = newValue
            setNeedsDisplay()
        }
        get {
            return axisScale
        }
    }
    
    private var axisScale: CGFloat = 50.0 {
        didSet {
            axisScale = min(max(axisScale, 1.0), 10000.0)
        }
    }
    
    weak var dataSource: GraphViewDataSource?

    private let axesDrawer = AxesDrawer()
    private var lastKnownDrawRect: CGRect?
    
    private var axisCenterOrigin: CGPoint?
    
    func scale(gesture: UIPinchGestureRecognizer) {
        if gesture.state == .Changed {
            let originalScale = axisScale
            axisScale *= gesture.scale
            if axisScale != originalScale {
                let resultGestureScale = axisScale / originalScale
                let gestureOrigin = gesture.locationInView(self)
                if axisCenterOrigin != nil {
                    axisCenterOrigin = CGPointMake(axisCenterOrigin!.x + (axisCenterOrigin!.x - gestureOrigin.x) * (resultGestureScale - 1),
                        axisCenterOrigin!.y + (axisCenterOrigin!.y - gestureOrigin.y) * (resultGestureScale - 1))
                }
            }
            gesture.scale = 1
            setNeedsDisplay()
        }
    }
    
    func pan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Ended: fallthrough
        case .Changed:
            let translation = gesture.translationInView(self)
            if axisCenterOrigin != nil {
                axisCenterOrigin = CGPointMake(axisCenterOrigin!.x + translation.x, axisCenterOrigin!.y + translation.y)
                gesture.setTranslation(CGPointZero, inView: self)
                setNeedsDisplay()
            }
        default: break
        }

    }
    
    func recenter(gesture: UITapGestureRecognizer) {
        axisCenterOrigin = gesture.locationInView(self)
        setNeedsDisplay()
    }
    
    private func pixelXToUnitX(pixelX: CGFloat) -> Double {
        return Double((pixelX - axisCenterOrigin!.x) / axisScale)
    }
    
    private func unitYtoPixelY(pointY: Double) -> CGFloat {
        return axisCenterOrigin!.y - axisScale * CGFloat(pointY)
    }
    
    override func drawRect(rect: CGRect) {
        // initial position
        if axisCenterOrigin == nil {
            axisCenterOrigin = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect))
        }
        
        // compensate for any size changes
        if lastKnownDrawRect != nil {
            axisCenterOrigin = CGPointMake(axisCenterOrigin!.x + (rect.width - lastKnownDrawRect!.width) / 2.0,
                axisCenterOrigin!.y + (rect.height - lastKnownDrawRect!.height) / 2.0)
        }
        lastKnownDrawRect = rect
        
        // draw the axes
        axesDrawer.drawAxesInRect(rect, origin: axisCenterOrigin!, pointsPerUnit: axisScale)
        
        // draw the function
        if let data = dataSource {
            CGContextSaveGState(UIGraphicsGetCurrentContext())
            let path = UIBezierPath()
            
            var lastDrawnValue: Double? = nil;
            for i in Int(0)...Int(rect.width) {
                if let value = data.evaluatedValue(self, xValue: pixelXToUnitX(CGFloat(i))) {
                    if value.isNormal || value.isZero {
                        if lastDrawnValue != nil {
                            path.addLineToPoint(CGPoint(x: CGFloat(i), y: unitYtoPixelY(value)))
                        } else {
                            path.moveToPoint(CGPoint(x: CGFloat(i), y: unitYtoPixelY(value)))
                        }
                        lastDrawnValue = value
                    } else {
                        lastDrawnValue = nil
                    }
                } else {
                    lastDrawnValue = nil
                }
            }
            path.stroke()
            CGContextRestoreGState(UIGraphicsGetCurrentContext())
        }
    }
}

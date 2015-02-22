//
//  GraphView.swift
//  Calculator
//
//  Created by Lyubomir Ganev on 22/02/15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

protocol GraphViewDataSource: class {
    func evaluatedValue(sender: GraphView, xValue: Double) -> Double
}

@IBDesignable
class GraphView: UIView {
    
    private var axesDrawer = AxesDrawer()

    @IBInspectable
    var scale: CGFloat = 50.0 {
        didSet {
            scale = min(max(scale, 1.0), 10000.0)
            setNeedsDisplay()
        }
    }
    
    weak var dataSource: GraphViewDataSource?
    
    private var initialGraphCenter: CGPoint?
    
    private var lastDrawRect: CGRect?
    
    private var graphCenter: CGPoint {
        get {
            if initialGraphCenter == nil {
                initialGraphCenter = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
            }
            return initialGraphCenter!
        }
        set {
            initialGraphCenter = newValue
        }
    }
    
    
    
    func scale(gesture: UIPinchGestureRecognizer) {
        if gesture.state == .Changed {
            let originalScale = scale
            scale *= gesture.scale
            if scale != originalScale {
                let gestureOrigin = gesture.locationInView(self)
                let fixCenterOffset = CGPointMake((graphCenter.x - gestureOrigin.x) * (gesture.scale - 1),
                    (graphCenter.y - gestureOrigin.y) * (gesture.scale - 1))
                
                graphCenter = CGPointMake(graphCenter.x + fixCenterOffset.x,
                    graphCenter.y + fixCenterOffset.y)
            }
            gesture.scale = 1
        }
    }
    
    func pan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Ended: fallthrough
        case .Changed:
            let translation = gesture.translationInView(self)
            graphCenter = CGPointMake(graphCenter.x + translation.x, graphCenter.y + translation.y)
            gesture.setTranslation(CGPointZero, inView: self)
            setNeedsDisplay()
        default: break
        }

    }
    
    func recenter(gesture: UITapGestureRecognizer) {
        graphCenter = gesture.locationInView(self)
        setNeedsDisplay()
    }
    
    private func pixelXToUnitX(pixelX: CGFloat) -> Double {
        return Double(pixelX / scale)
    }
    
    private func unitYtoPixelY(pointY: Double) -> CGFloat {
        return scale * CGFloat(pointY)
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        if let lastDrawRect = lastDrawRect {
            graphCenter = CGPointMake(graphCenter.x + (rect.width - lastDrawRect.width) / 2.0,
                graphCenter.y + (rect.height - lastDrawRect.height) / 2.0)
        }
        lastDrawRect = rect
        
        axesDrawer.drawAxesInRect(rect, origin: graphCenter, pointsPerUnit: scale)
        
        // TODO: draw the line
        for i in Int(0)...Int(rect.width) {
            
        }
    }
}

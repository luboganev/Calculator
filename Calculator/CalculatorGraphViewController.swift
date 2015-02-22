//
//  CalculatorGraphViewController.swift
//  Calculator
//
//  Created by Lyubomir Ganev on 22/02/15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

class CalculatorGraphViewController: UIViewController, GraphViewDataSource {
    
    private let brain = CalculatorBrain()
    
    var program: AnyObject? {
        didSet {
            if let newProgram: AnyObject = program {
                brain.program = newProgram
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = brain.shortDescription
    }

    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.dataSource = self
            graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphView, action: "scale:"))
            graphView.addGestureRecognizer(UIPanGestureRecognizer(target: graphView, action: "pan:"))
            let doubleTapRecognizer = UITapGestureRecognizer(target: graphView, action: "recenter:")
            doubleTapRecognizer.numberOfTapsRequired = 2
            graphView.addGestureRecognizer(doubleTapRecognizer)
        }
    }
    
    func evaluatedValue(sender: GraphView, xValue: Double) -> Double? {
        brain.variableValues.updateValue(xValue, forKey: "M")
        return brain.evaluate()
    }
}

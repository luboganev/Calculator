//
//  ViewController.swift
//  Calculator
//
//  Created by Lyubomir Ganev on 29/01/15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {
    
    @IBOutlet weak var display: UILabel!
    
    @IBOutlet weak var history: UILabel!
    
    var userIsInTheMiddleOfTypingANumber = false
    
    var brain = CalculatorBrain()
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        updateHistory()
    }
    
    @IBAction func appendDigit(sender: UIButton) {
        let digit = sender.currentTitle!
        if userIsInTheMiddleOfTypingANumber {
            display.text = display.text! + digit
        } else {
            userIsInTheMiddleOfTypingANumber = true
            display.text = digit
        }
    }
    
    @IBAction func appendPoint(sender: UIButton) {
        let pointSymbol = sender.currentTitle!
        if userIsInTheMiddleOfTypingANumber {
            if display.text?.rangeOfString(pointSymbol) == nil {
                display.text = display.text! + pointSymbol
                
            }
        } else {
            userIsInTheMiddleOfTypingANumber = true
            display.text = "0" + pointSymbol
        }
    }

    @IBAction func enter() {
        if displayValue == nil {
            return
        }
        
        userIsInTheMiddleOfTypingANumber = false
        displayValue = brain.pushOperand(displayValue!)
        updateHistory()
    }
    
    @IBAction func operate(sender: UIButton) {
        if let operation = sender.currentTitle {
            if userIsInTheMiddleOfTypingANumber {
                if operation == "⁺/₋" {
                    if let oldDisplayValue = displayValue {
                        if oldDisplayValue.isSignMinus {
                            display.text = String((display.text!).characters.dropFirst())
                        }
                        if !oldDisplayValue.isZero {
                            display.text = "-" + display.text!
                        }
                    }
                    return
                } else {
                    enter()
                }
            }
            
            displayValue = brain.performOperation(operation)
            updateHistory()
        }
        
    }
    
    @IBAction func clear() {
        brain.clear()
        brain.variableValues.removeAll(keepCapacity: false)
        resetDisplayText()
        updateHistory()
    }
    
    @IBAction func backspace() {
        if(!userIsInTheMiddleOfTypingANumber) {
            displayValue = brain.undoOp()
            updateHistory()
            return
        }
        
        if (display.text!).characters.count > 1 {
            display.text = String((display.text!).characters.dropLast())
        } else {
            resetDisplayText()
        }
    }
    
    private let MEMORY_VARIABLE_NAME = "M"
    
    @IBAction func pushMemory(sender: AnyObject) {
        userIsInTheMiddleOfTypingANumber = false
        displayValue = brain.pushOperand(MEMORY_VARIABLE_NAME)
        updateHistory()
    }
    
    
    @IBAction func setMemoryValue(sender: AnyObject) {
        if let newMemoryValue = displayValue {
            userIsInTheMiddleOfTypingANumber = false
            brain.variableValues.updateValue(newMemoryValue, forKey: MEMORY_VARIABLE_NAME)
            displayValue = brain.evaluate()
            updateHistory()
        }
    }
    
    private func updateHistory() {
        history.text = brain.description
    }
    
    private func resetDisplayText() {
        display.text = "0"
        userIsInTheMiddleOfTypingANumber = false
    }
    
    var displayValue: Double? {
        get {
            if let displayText = display.text {
                return NSNumberFormatter().numberFromString(displayText)?.doubleValue
            }
            return nil
        }
        set {
            if let newNumber = newValue {
                display.text = "\(newNumber)"
            } else {
                display.text = nil
            }
            userIsInTheMiddleOfTypingANumber = false
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
                case "Show Graph":
                    if let navc = segue.destinationViewController as? UINavigationController {
                        if let vc = navc.viewControllers[0] as? CalculatorGraphViewController {
                            vc.program = brain.program
                    }
                }
                default: break
            }
        }
    }
}


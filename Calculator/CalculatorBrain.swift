//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Lyubomir Ganev on 30/01/15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import Foundation

class CalculatorBrain {
    
    // The internal helper data structure allowing us to differentiate 
    // between the different inputs in the CalculatorBrain
    private enum Op: CustomStringConvertible {
        case Operand(Double) // A double number
        case Variable(String) // A variable operand
        case ConstantOperation(String, () -> Double) // An operation returning a constant value
        case UnaryOperation(String, Double -> Double) // An operation with 1 argument
        case BinaryOperation(String, Int, (Double, Double) -> Double) // An operation with 2 arguments
        
        var description: String {
            get {
                switch self {
                case .Operand(let operand):
                    return "\(operand)"
                case .Variable(let variableName):
                    return variableName
                case .ConstantOperation(let constantName, _):
                    return constantName
                case .UnaryOperation(let symbol, _):
                    return symbol
                case .BinaryOperation(let symbol, _, _):
                    return symbol
                }
            }
        }
        
        var precedence: Int {
            get {
                switch self {
                case .BinaryOperation(_, let precedence, _):
                    return precedence
                default:
                    return Op.defaultPrecedence()
                }
                
            }
        }
        
        static func defaultPrecedence() -> Int {
            return Int.max
        }
    }
    
    // The stack of operations and operands where we push incoming input
    private var opStack = [Op]()
    
    // An dictionary of the know operations which is used to 
    // translate the operation symbol into an Op
    private var knownOps = [String:Op]()
    
    init() {
        func learnOp(op: Op) {
            knownOps[op.description] = op
        }
        
        // learn the known operations
        learnOp(Op.BinaryOperation("×", 2, *))
        learnOp(Op.BinaryOperation("÷", 2) { $1 / $0 })
        learnOp(Op.BinaryOperation("+", 1, +))
        learnOp(Op.BinaryOperation("−", 1) { $1 - $0 })
        learnOp(Op.UnaryOperation("⁺/₋", { -$0 }))
        learnOp(Op.UnaryOperation("√", sqrt))
        learnOp(Op.UnaryOperation("sin", sin))
        learnOp(Op.UnaryOperation("cos", cos))
        learnOp(Op.ConstantOperation("π", { M_PI }))
    }
    
    // Evaluates recursively the ops stack
    // returns the result of the evaluation and the remaining portion of the stack
    private func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op]) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
            case .Operand(let operand):
                return (operand, remainingOps)
            case .Variable(let variableName):
                if let variableValue = variableValues[variableName] {
                    return (variableValue, remainingOps)
                }
                return (nil, remainingOps)
            case .ConstantOperation(_, let operation):
                return (operation(), remainingOps)
            case .UnaryOperation(_, let operation):
                let operandEvaluation = evaluate(remainingOps)
                if let operand = operandEvaluation.result {
                    return (operation(operand), operandEvaluation.remainingOps)
                }
            case .BinaryOperation(_, _, let operation):
                let op1Evaluation = evaluate(remainingOps)
                if let operand1 = op1Evaluation.result {
                    let op2Evaluation = evaluate(op1Evaluation.remainingOps)
                    if let operand2 = op2Evaluation.result {
                        return (operation(operand1, operand2), op2Evaluation.remainingOps)
                    }
                }
            }
        }
        return (nil, ops)
    }
    
    // Evaluates the whole brain and returns the result of that operation
    func evaluate() -> Double? {
        let (result, remainder) = evaluate(opStack)
        return result
    }
    
    // Pushes an operand to the ops stack and immediately evaluates
    func pushOperand(operand: Double) -> Double? {
        opStack.append(Op.Operand(operand))
        return evaluate()
    }
    
    // Pushes an operation to the ops stack and immediately evaluates
    func performOperation(symbol: String) -> Double? {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
        }
        return evaluate()
    }
    
    // Pushes a variable operand to the ops stack
    func pushOperand(operandVariable: String) -> Double? {
        opStack.append(Op.Variable(operandVariable))
        return evaluate()
    }
    
    // Removes the last operation from the ops stack and recalculates it
    func undoOp() -> Double? {
        if !opStack.isEmpty {
            opStack.removeLast()
        }
        return evaluate()
    }
    
    // Sets or gets the values of the variable operands in the ops stack
    var variableValues: Dictionary<String, Double> = Dictionary<String, Double>()
    
    // Clears the ops stack from its contents
    func clear() {
        opStack.removeAll(keepCapacity: false)
    }
    
    // Returns a visual pretty representation of the
    // current state of the ops stack
    var description: String {
        get {
            if opStack.isEmpty {
                return "Empty"
            }
            
            var prettyFormat = ""
            var (result, _, remainingOps) = history(opStack)
            prettyFormat += result
            while !remainingOps.isEmpty {
                (result, _, remainingOps) = history(remainingOps)
                prettyFormat = result + " , " + prettyFormat
            }
            
            switch opStack.last! {
            case Op.ConstantOperation(_, _):
                fallthrough
            case Op.Operand(_):
                break;
            default:
                prettyFormat += "="
            }
            
            return prettyFormat
        }
    }
    
    var shortDescription: String {
        get {
            if opStack.isEmpty {
                return "Empty"
            }
            return history(opStack).result
        }
    }
    
    
    // Evaluates recursively the ops stack and
    // returns the string representing the pretty format of the ops
    private func history(ops: [Op]) -> (result: String, opPrecedence: Int, remainingOps: [Op]) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            let currentOpPrecedence = op.precedence
            switch op {
            case .Operand(let operand):
                return ("\(operand)", currentOpPrecedence, remainingOps)
            case .Variable(let variableName):
                return (variableName, currentOpPrecedence, remainingOps)
            case .ConstantOperation(let operationName, _):
                return (operationName, currentOpPrecedence, remainingOps)
            case .UnaryOperation(let operationName, _):
                let operandEvaluation = history(remainingOps)
                let result = operationName + "(" + operandEvaluation.result + ")"
                return (result, currentOpPrecedence, operandEvaluation.remainingOps)
            case .BinaryOperation(let operationName, _, _):
                let op1Evaluation = history(remainingOps)
                let op2Evaluation = history(op1Evaluation.remainingOps)
                
                var result = ""
                
                if op2Evaluation.opPrecedence < currentOpPrecedence {
                    result += "(" + op2Evaluation.result + ")"
                } else {
                    result += op2Evaluation.result
                }
                
                result += operationName
                
                if op1Evaluation.opPrecedence < currentOpPrecedence {
                    result += "(" + op1Evaluation.result + ")"
                } else {
                    result += op1Evaluation.result
                }

                return (result, currentOpPrecedence, op2Evaluation.remainingOps)
            }
        }
        return ("?", Op.defaultPrecedence(), ops)
    }
    
    var program: AnyObject { //PropertyList
        get {
            return opStack.map { $0.description }
        }
        set {
            if let opSymbols = newValue as? Array<String> {
                var newOpStack = [Op]()
                for opSymbol in opSymbols {
                    if let op = knownOps[opSymbol] {
                        newOpStack.append(op)
                    } else if let operand = NSNumberFormatter().numberFromString(opSymbol)?.doubleValue {
                        newOpStack.append(.Operand(operand))
                    } else {
                        newOpStack.append(.Variable(opSymbol))
                    }
                }
                opStack = newOpStack
            }
        }
    }
}

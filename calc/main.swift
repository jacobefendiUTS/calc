//
//  main.swift
//  calc
//
//  Created by Jacob Efendi on 12/3/18.
//  Copyright © 2018 UTS. All rights reserved.
//

import Foundation

// main function
func Evaluate (operation: String) -> Int {
    
    // initialise variable to contain operation array
    var operationArray: Array<String> = []
    
    // try and get the operation as an evaluable array
    do {
        try operationArray = GetOperationAsArray(operation: operation)
    } catch CalculatorError.InvalidCharacter(let input) {
        // catch error and end program if invalid input was found
        print("Invalid number: \(input)")
        exit(1)
    } catch {
        // generic error catch statement
        print("Error Found")
        exit(1)
    }
    
    return GetOperationResult(operation: operationArray)
}

// function to return operation as evaluable array
func GetOperationAsArray(operation: String) throws -> Array<String> {
    // remove spaces from string
    let newOperation = operation.replacingOccurrences(of: " ", with: "")
    // initialise array to contain operation
    var operationArray: [String] = []
    // initialise string to contain unary operators (+/-) to be place in front of numbers
    var unaryOperator: String = "";
    
    // convert operation into array of strings
    for digit in newOperation {
        operationArray.append(String(digit))
    }
    
    // initialise counter variable
    var i: Int = 0;
    
    /*
     loop through the operation and do the following:
     - save and add unary operator to numbers, e.g. "-", "1" becomes "-1"
     - put digits together e.g. "3", "0", "0" becomes "300"
    */
    while i < operationArray.count {
        
        // get the current digit being check
        var digit = operationArray[i]
        
        // if the current digit is an operator, check if it is part of a number (unary) or not
        if (IsOperator(digit: digit)) {
            // get the digit that is after the operator being check
            let nextDigit: String = operationArray[i + 1]
            
            /*
                the operator is at the start of the operation before a number
                therefore it is part of the number
            */
            if (i == 0 && IsNumber(digit: nextDigit)) {
                // set the unary operator variable to the current operator
                unaryOperator = digit
                // remove the operator from the array
                operationArray.remove(at: i)
                i -= 1
            }
            /*
                 the operator is in the middle of operation an inbetween another operator and a number
                 therefore it is part of a number
            */
            else if (IsOperator(digit: operationArray[i - 1]) && IsNumber(digit: nextDigit)) {
                unaryOperator = digit
                operationArray.remove(at: i)
                i -= 1
            }
            /*
                the operator is at the start of the operation but high precedence
                therefore it is not a valid unary operator
            */
            else if (i == 0 && IsHighPrecedence(digit: digit)){
                throw CalculatorError.InvalidCharacter(input: digit)
            }
        }
        /*
                if the digit is a number, concatenate proceeding numbers until an operator is reached
                e.g. ["3", "0", "0"] will become ["300"]
        */
        else if (IsNumber(digit: digit)) {
            
            // initialise variable to contain the digit after the current digit
            var nextDigit: String = "";
            if (i + 1 < operationArray.count) { nextDigit = operationArray[i + 1] }
            
            // while the next digit is a number, add it to the current digit
            while IsNumber(digit: nextDigit) {
                // add the next digit to the current digit
                digit += nextDigit
                // remove the next digit as it is already added to the current
                operationArray.remove(at: i + 1)
                // see if there is another digit available to check
                if (i + 1 < operationArray.count) { nextDigit = operationArray[i + 1] }
                else { break }
            }
        }
        // if the current digit is not an operator or number, throw an invalidcharacter error
        else {
            throw CalculatorError.InvalidCharacter(input: digit)
        }
        
        // if the current digit is a number, check if there is a unary operator and add it on
        if (IsNumber(digit: digit)) {
            // check if there is a unary operator (+/-) that can be added to the number
            if (unaryOperator != "") {
                // add the operator to the number
                digit = unaryOperator + digit
                // clear the unary operator variable
                unaryOperator = ""
            }
            
            // increase counter to move further into the operation
            operationArray[i] = digit
        }
        
        i += 1
    }
    
    return operationArray
}

/*
 function to get value of the complete operation
 involves:
    - looping through equation twice to calculate high precedence and low precedence parts separately
    - calculating parts of operation with high precedence operators first
    - operation is updated with high precedence parts solved e.g. 10 + 3 x 4 becomes 10 + 12
    - calculating parts of updated operation with low precedence operators and returning the total result
*/
func GetOperationResult(operation: Array<String>) -> Int {
    
    // initialise value to contain total/result
    var total: Int = 0;
    // initialise counter value
    var i: Int = 0;
    // copy operation array to version that can be manipulated
    var operationArray: [String] = operation

    // move through operation until we reach the end of it
    while i < operationArray.count {
        
        // calculate parts of operation with high precedence operators first
        if (IsHighPrecedence(digit: operationArray[i])) {
            // initialise variable to contain total of high precedecene operations
            var result: Int = 0
            
            do {
                /*
                try and calculate the high precedence operation
                leftValue is the number which appears before the high precedence operator
                rightValue is the number which appears after the high precedence operator
                */
                try result = Calculate(leftValue: operationArray[i - 1], op: operationArray[i], rightValue: operationArray[i + 1])
            } catch CalculatorError.DivisionByZero {
                // catch error and end program if a division by zero was attempted
                print("Division by Zero")
                exit(1)
            } catch {
                // generic error catch statement
                print("Error Found")
                exit(1)
            }
            
            // place result of operation where the operator originally was
            operationArray[i] = String(result)
            // remove left and right values as they have already been calculated
            operationArray.remove(at: i + 1)
            operationArray.remove(at: i - 1)
            
            // reset counter value so we can scan the updated operation from the beginning
            i = 0
        }
        
        // increase counter to move further into the operation
        i += 1
    }
    
    if (operationArray.count == 1) {
        // if there are no more operators in the operation, return the result
        if let total = Int(operationArray[0]) {
            return total
        }
    }
    else {
        
        // otherwise, reset the counter and go through the equation again
        i = 0
        
        // complete the remaining low precedence parts of the operation until we reach the end of it
        // similar approach to how the high precedence parts are calculated
        while i < operationArray.count {
            
            if (IsLowPrecedence(digit: operationArray[i])) {
                
                // initialise variable to contain result
                var result: Int = 0
                
                do {
                    // calculate value of operation between left and right values if an operator is found
                    try result = Calculate(leftValue: operationArray[i - 1], op: operationArray[i], rightValue: operationArray[i + 1])
                } catch {
                    // generic error catch statement
                    print("Error Found")
                    exit(1)
                }
                
                total = result // update the total value of the operation
                
                // replace operator with the current total
                operationArray[i] = String(total)
                // remove left and right values as they have already been calculated
                operationArray.remove(at: i + 1)
                operationArray.remove(at: i - 1)
                
                // reset counter so we scan the operation from the beginning again
                i = 0
            }
            // increase counter to move further along operation
            i += 1
        }
    }
    
    // return the total value calculated
    return total
}

// function to calculate equation between two values
func Calculate(leftValue: String, op: String, rightValue: String) throws -> Int {
    // if the left and right values are numbers, calculate based on the provided operator
    if let x: Int = Int(leftValue), let y: Int = Int(rightValue) {
        switch op {
        case "+": // addition
            return x + y
        case "-": // subtraction
            return x - y
        case "x": // multiplication
            return x * y
        case "/": // division
            // only divide if the divisor is not 0
            if (y != 0) {
                return x / y
            }
            else {
                // otherwise, throw division by zero error
                throw CalculatorError.DivisionByZero
            }
        case "%": // modulus
            // only modulus if the divisor is not 0
            if (y != 0) {
                return x % y
            }
            else {
                // otherwise, throw division by zero error
                throw CalculatorError.DivisionByZero
            }
        default:
            // default case, return 0
            return 0;
        }
    }
    else {
        // otherwise, return 0 if equation cannot be complete
        return 0;
    }
}

func IsNumber(digit: String) -> Bool {
    // array containing numbers
    let numbers = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    // loop to compare if provided digit has numbers
    for number in numbers {
        // return true if a match is found
        if (digit.contains(number)) { return true }
    }
    // otherwise, return false if a match is not found
    return false
}

// function to check if provided digit is an operator (+, -, x, /, %)
func IsOperator(digit: String) -> Bool {
    // array containing operators
    let operators = ["+", "-", "x", "/", "%"]
    // loop to compare provided digit with operators
    for op in operators {
        // return true if a match is found
        if (digit == op) { return true }
    }
    // otherwise, return false if a match is not found
    return false
}

// function to check if operator is of high precedence (x, /, %)
func IsHighPrecedence(digit: String) -> Bool {
    // array containing high precedence operators
    let operators = ["x", "/", "%"]
    // loop to compare provided digit with operators
    for op in operators {
        // return true if a match is found
        if (digit == op) { return true }
    }
    // otherwise, return false if a match is not found
    return false
}

// function to check if operator is of low precedence (+, -)
func IsLowPrecedence(digit: String) -> Bool {
    // array containing low precedence operators
    let operators = ["+", "-"]
    // loop to compare provided digit with operators
    for op in operators {
        // return true if a match is found
        if (digit == op) { return true }
    }
    // otherwise, return false if a match is not found
    return false
}

// enum to contain error cases
enum CalculatorError: Error {
    case DivisionByZero
    case InvalidCharacter(input: String)
}

// main routine

var args = ProcessInfo.processInfo.arguments
args.removeFirst() // remove the name of the program
var result : Int = Evaluate(operation: args.joined())
print (result)

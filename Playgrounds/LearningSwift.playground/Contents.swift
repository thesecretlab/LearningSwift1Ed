// Playground - noun: a place where people can play

// This playground goes with Learning Swift.

import UIKit

// Comments

// BEGIN comments
// This is a single line comment.

/* This is a multiple-line
    comment. */

/* 
 This is a comment.
 
 /* This is also a comment, inside the first! */
 
 Still a comment!
*/
// END comments

// ------
// Variables and Constants
// BEGIN variables_and_constants
var myVariable = 123
let myConstantVariable = 123
// END variables_and_constants

#if os(NOPE)
// BEGIN changing_constant_var
myVariable += 5
    
    
myConstantVariable += 2
// (ERROR: can't change a constant variable)
// END changing_constant_var
#endif

// Multiple lines
// BEGIN multiple_lines
var someVariable =
"Yes"
// END multiple_lines

// Multiple statements
// BEGIN multiple_statements
someVariable = "No"; print(someVariable)
// END multiple_statements

#if os(NOPE)
// BEGIN must_assign_value_to_constants
let someConstant : Int
// ERROR: constants must contain values when they're declared
// END must_assign_value_to_constants
#endif

#if os(NOPE)
// BEGIN cant_use_variables_before_they_have_value
var someVariable : Int
someVariable += 2
// ERROR: someVariable doesn't have a value, so can't add 2 to it
someVariable = 2
someVariable += 2
// WORKS, because someVariable has a value to add to
// END cant_use_variables_before_they_have_value
#endif

// ------
// Operators

// BEGIN basic_operators
1 + 7 // 8
6 - 5 // 1
4 / 2 // 2
4 * 0 // 0
// END basic_operators

// BEGIN equality_operators
2 == 2 // true
2 != 2 // false
"yes" == "no" // false
"yes" != "no" // true
// END equality_operators

// BEGIN dot_operator
true.description // "true"
4.advancedBy(3) // 7
// END dot_operator

// ------
// Types

// BEGIN implicit_type
// Implicit type of integer
var anInteger = 2
// END implicit_type

anInteger += 3

anInteger += Int(0.2)

var aFloat = 0.0

aFloat += 0.2

aFloat += 1

#if os(NOPE)
// BEGIN incompatible_types
// ERROR: Can't add a string to an integer
anInteger += "Yes"
// END incompatible_types
#endif

// BEGIN explicit_type
// Explicit type of integer
let anExplicitInteger : Int = 2
// END explicit_type

// BEGIN optional_type
// Optional integer, allowed to be nil
var anOptionalInteger : Int? = nil
anOptionalInteger = 42
// END optional_type

#if os(NOPE)
// BEGIN optional_type_error
// Nonoptional (regular), NOT allowed to be nil
var aNonOptionalInteger = 42

aNonOptionalInteger = nil
// ERROR: only optional values can be nil
// END optional_type_error
#endif

// BEGIN optional_type_checking
if anOptionalInteger != nil {
    print("It has a value!")
} else {
    print("It has no value!")
}
// END optional_type_checking

// Use an 'if false' here to prevent a crash due to deliberately 'broken' code in the following example
if false {
    // BEGIN optional_unwrapping
    // Optional types must be unwrapped using !
    anOptionalInteger = 2
    1 + anOptionalInteger! // = 3
    
    anOptionalInteger = nil
    1 + anOptionalInteger!
    // CRASH: anOptionalInteger = nil, can't use nil data
    // END optional_unwrapping
}

// Optionals can also be declared unwrapped; this means you don't have to unwrap them later, but is unsafe
// BEGIN optional_declared_unwrapped
var implicitlyUnwrappedOptionalInteger : Int!
implicitlyUnwrappedOptionalInteger = 1
1 + implicitlyUnwrappedOptionalInteger // = 2
// END optional_declared_unwrapped

// Types can be converted
// BEGIN converting_types
let aString = String(2)
// = "2"
// END converting_types

#if os(NOPE)
// BEGIN cant_directly_convert_types
// ERROR: Can't directly convert between types
let aString = anInteger
// END cant_directly_convert_types
#endif

// Tuples
// BEGIN tuples
let aTuple = (1, "Yes")
// END tuples

// BEGIN tuples_accessing
let theNumber = aTuple.0 // = 1
// END tuples_accessing

// BEGIN tuples_accessing_string
let anotherTuple = (aNumber: 1, aString: "Yes")

let theOtherNumber = anotherTuple.aNumber // = 1
// END tuples_accessing_string

// ------
// Arrays

// BEGIN explicit_array
// Array of integers
let arrayOfIntegers : [Int] = [1,2,3]
// END explicit_array

// BEGIN implicit_array
// Type of array is implied
let implicitArrayOfIntegers = [1,2,3]
// END implicit_array

// BEGIN create_empty_array
// You can also create an empty array, but you must provide the type
let anotherArray = [Int]()
// END create_empty_array

// Arrays can be immutable, like all other types
// BEGIN immutable_array
let immutableArray = [42,24]
// END immutable_array

// Adding values to arrays
// BEGIN appending_to_array
var myArray = [1,2,3]
myArray.append(4)
// = [1,2,3,4]
// END appending_to_array

// Getting the number of items in an array
// BEGIN array_count
myArray.count
// = 4
// END array_count

// Inserting values in arrays
// BEGIN inserting_in_array
myArray.insert(5, atIndex: 0)
// = [5,1,2,3,4]
// END inserting_in_array

// Removing items from arrays
// BEGIN removing_from_array
myArray.removeAtIndex(4)
// = [5,1,2,3]
// END removing_from_array

// Reversing an array
// BEGIN reversing_array
myArray.reverse()
// = [3,2,1,5]
// END reversing_array

// ------
// Dictionaries

// Creating a dictionary of string keys and string values
// BEGIN creating_dictionary
var crew = [
    "Captain": "Benjamin Sisko",
    "First Officer": "Kira Nerys",
    "Constable": "Odo"
];
// END creating_dictionary

// Retrieving values from a dictionary
// BEGIN values_from_dict
crew["Captain"]
// = "Benjamin Sisko"
// END values_from_dict

// Setting values in a dictionary
// BEGIN setting_values_in_dict
crew["Doctor"] = "Julian Bashir"
// END setting_values_in_dict

// Dictionaries can contain any type
// BEGIN integer_keys_in_dict
// This dictionary uses integers for both keys and values
var aNumberDictionary = [1: 2]
aNumberDictionary[21] = 23
// END integer_keys_in_dict

// BEGIN mixed_dict
var aMixedDictionary = ["one": 1, "two": "twoooo"]
// the type of this dictionary is [String: NSObject],
// allowing it to have basically any type of value
// END mixed_dict

// ------
// Flow control (loops, if)

// BEGIN if_block
if 1+1 == 2 {
    print("The math checks out")
}
// Prints "The math checks out", which is a relief
// END if_block

// For loops a for-in loop
// BEGIN for_in_loop
let loopingArray = [1,2,3,4,5]
var loopSum = 0
for number in loopingArray {
    loopSum += number
}
loopSum // = 15
// END for_in_loop

// Ranges can be ..< (exclusive) and ... (inclusive)
// BEGIN for_range_exclusive
var firstCounter = 0
for index in 1 ..< 10 {
    firstCounter += 1
}
// Loops 9 times
// END for_range_exclusive
print("Looped \(firstCounter) times")

// BEGIN for_range_inclusive
var secondCounter = 0
for index in 1 ... 10 { // note the three dots, not two
    secondCounter += 1
}
// Loops 10 times
// END for_range_inclusive
print("Looped \(secondCounter) times")

// While loop
// BEGIN while_loop
var countDown = 5
while countDown > 0 {
    countDown -= 1
}
countDown // = 0
// END while_loop

// Do-while loop
// BEGIN do_while_loop
var countUp = 0
repeat {
    countUp += 1
} while countUp < 5
countUp // = 5
// END do_while_loop

// Using If-let to unwrap conditions
// BEGIN if_let
var conditionalString : String? = "a string"

if let theString = conditionalString {
    print("The string is '\(theString)'")
} else {
    print("The string is nil")
}
// Prints "The string is 'a string'"
// END if_let

// ------
// Switches

// Switching on an integer
// BEGIN switch_on_integer
let integerSwitch = 3

switch integerSwitch {
case 0:
    print("It's 0")
case 1:
    print("It's 1")
case 2:
    print("It's 2")
default: // note: default is mandatory if not all
    // cases are covered (or can be covered)
    print("It's something else")
}
// Prints "it's something else"
// END switch_on_integer

// Switching on a string
// BEGIN switch_on_string
let stringSwitch = "Hello"

switch stringSwitch {
case "Hello":
    print("A greeting")
case "Goodbye":
    print("A farewell")
default:
    print("Something else")
}
// Prints "A greeting"
// END switch_on_string

// Switching on a tuple
// BEGIN switch_on_tuple
let tupleSwitch = ("Yes", 123)

switch tupleSwitch {
case ("Yes", 123):
    print("Tuple contains 'Yes' and '123'")
case ("Yes", _):
    print("Tuple contains 'Yes' and something else")
case (let string, _):
    print("Tuple contains the string '\(string)' and something else")
default:
    break
}
// Prints "Tuple contains 'Yes' and '123'"
// END switch_on_tuple

// Switching on a range
// BEGIN switch_on_range
var someNumber = 15

switch someNumber {
case 0...10:
    print("Number is between 0 and 10")
case 11...20:
    print("Number is between 11 and 20")
case 21:
    print("Numer is 21!")
default:
    print("Number is something else")
}
// Prints "Number is between 11 and 20"
// END switch_on_range

// BEGIN switch_fallthrough
let fallthroughSwitch = 10

switch fallthroughSwitch {
case 0..<20:
    print("Number is between 0 and 20")
    fallthrough
case 0..<30:
    print("Number is between 0 and 30")
default:
    print("Number is something else")
}
// Prints "Number is between 0 and 20" and then "Number is between 0 and 30"
// END switch_fallthrough

// ------ Defer and Guard

// BEGIN defer_example
func doSomeWork() {
    print("Getting started!")
    defer {
        print("All done!")
    }
    print("Getting to work!")
}

doSomeWork()
// Prints "Getting started!", "Getting to work!" and "All done!", in that order
// END defer_example

func doSomeMoreWork() {
    // BEGIN guard_example
    guard 2+2 == 4 else {
        print("The universe makes no sense")
        return // this is mandatory!
    }
    print("We can continue with our daily lives")
    // END guard_example
}


// ------
// Functions

// Defining a function with no parameters and no return
// BEGIN function
func sayHello() {
    print("Hello")
}

sayHello()
// END function

// Defining a function that returns a value
// BEGIN function_returning_value
func usefulNumber() -> Int {
    return 123
}

usefulNumber()
// END function_returning_value

// Defining a function that takes parameters
// BEGIN function_with_parameters
func addNumbers(firstValue: Int, secondValue: Int) -> Int {
    return firstValue + secondValue
}

addNumbers(1, secondValue: 2)
// END function_with_parameters

// Functions can return multiple values, using a tuple
// BEGIN function_returning_tuple
func processNumbers(firstValue: Int, secondValue: Int)
    -> (doubled: Int, quadrupled: Int) {
        return (firstValue * 2, secondValue * 4)
}
processNumbers(2, secondValue: 4)
// END function_returning_tuple

// If a returned tuple has named components (which is optional), you can refer
// to those components by name:
// BEGIN access_components_of_tuple
// Accessing by number:
processNumbers(2, secondValue: 4).1 // = 16
// Same thing but with names:
processNumbers(2, secondValue: 4).quadrupled // = 16
// END access_components_of_tuple

// BEGIN function_with_no_parameter_names
func subtractNumbers(num1 : Int, _ num2 : Int) -> Int {
    return num1 - num2
}

subtractNumbers(5, 3) // = 2
// END function_with_no_parameter_names

// Function parameters can be given names
// BEGIN function_with_parameter_names
func addNumber(firstNumber num1 : Int, toSecondNumber num2: Int) -> Int {
    return num1 + num2
}

addNumber(firstNumber: 2, toSecondNumber: 3) // = 5
// END function_with_parameter_names

// You can shorthand this by adding a #
// BEGIN function_with_shorthand_method_names

// OBSOLETE

//func multiplyNumbers(#firstNumber: Int, #multiplier: Int) -> Int {
//    return firstNumber * multiplier
//}
//multiplyNumbers(firstNumber: 2, multiplier: 3) // = 6
// END function_with_shorthand_method_names

// Function parameters can have default values, as long as they're at the end
// BEGIN function_with_default_parameter_values
func multiplyNumbers2 (firstNumber: Int, multiplier: Int = 2) -> Int {
    return firstNumber * multiplier;
}
// Parameters with default values can be omitted
multiplyNumbers2(2) // = 4
// END function_with_default_parameter_values

// Functions can receive a variable number of parameters
// BEGIN function_with_variable_parameters
func sumNumbers(numbers: Int...) -> Int {
    // in this function, 'numbers' is an array of Ints
    var total = 0
    for number in numbers {
        total += number
    }
    return total
}
sumNumbers(2,3,4,5) // = 14
// END function_with_variable_parameters

// Functions can change the value of variables that get passed to them using 'inout'
// BEGIN function_using_inout_to_swap
func swapValues(inout firstValue: Int, inout _ secondValue: Int) {
    (firstValue, secondValue) = (secondValue, firstValue)
}

var swap1 = 2
var swap2 = 3
swapValues(&swap1, &swap2)
swap1 // = 3
swap2 // = 2
// END function_using_inout_to_swap


// ------
// Closures and Function Types

// Functions can be stored in variables
// BEGIN storing_function_in_variable
var numbersFunc: (Int, Int) -> Int;
// numbersFunc can now store any function that takes two ints and returns an int

// Using the 'addNumbers' function from before, which takes two numbers
// and adds them
numbersFunc = addNumbers
numbersFunc(2, 3) // = 5
// END storing_function_in_variable

// Functions can receive other functions as parameters
// BEGIN function_receiving_function_as_parameter
func timesThree(number: Int) -> Int {
    return number * 3
}

func doSomethingToNumber(aNumber: Int, thingToDo: (Int)->Int) -> Int {
    // we've received some function as a parameter, which we refer to as
    // 'thingToDo' inside this function.
    
    // call the function 'thingToDo' using 'aNumber', and return the result
    return thingToDo(aNumber);
}

// Give the 'timesThree' function to use as 'thingToDo'
doSomethingToNumber(4, thingToDo: timesThree) // = 12
// END function_receiving_function_as_parameter

// Functions can return other functions
// BEGIN function_returning_function
// This function takes an Int as a parameter. It returns a new function that
// takes an Int parameter and return an Int.
func createAdder(numberToAdd: Int) -> (Int) -> Int {
    func adder(number: Int) -> Int {
        return number + numberToAdd
    }
    return adder
}
var addTwo = createAdder(2)

// addTwo is now a function that can be called
addTwo(2) // = 4
// END function_returning_function

// Functions can 'capture' values
// BEGIN function_capturing_values
func createIncrementor(incrementAmount: Int) -> () -> Int { // <1>
    var amount = 0 // <2>
    func incrementor() -> Int { // <3>
        amount += incrementAmount // <4>
        return amount
    }
    return incrementor // <5>
}

var incrementByTen = createIncrementor(10) // <6>
incrementByTen() // = 10 <7>
incrementByTen() // = 20

var incrementByFifteen = createIncrementor(15) // <8>
incrementByFifteen() // = 15 <9>
// END function_capturing_values

// You can write short, anonymous functions called 'closures'
// BEGIN using_closure_as_parameter
var numbers = [2,1,56,32,120,13]

// Sort so that small numbers go before large numbers
var numbersSorted = numbers.sort({
    (n1: Int, n2: Int) -> Bool in return n2 > n1
})
// = [1, 2, 13, 32, 56, 120]
// END using_closure_as_parameter

// The types of parameters and the return type can be inferred
// BEGIN closure_with_inferred_parameter_types
var numbersSortedReverse = numbers.sort({n1, n2 in return n1 > n2})
// = [120, 56, 32, 13, 2, 1]
// END closure_with_inferred_parameter_types


// If you don't care about the names of the parameters, use $0, $1, etc
// Also, if there's only a single line of code in the closure you can omit the 'return'
// BEGIN closure_with_anonymous_parameters_and_no_return_keyword
var numbersSortedAgain = numbers.sort({
    $1 > $0
}) // = [1, 2, 13, 32, 56, 120]
// END closure_with_anonymous_parameters_and_no_return_keyword

// If the last parameter of a function is a closure, you can put the braces outside the parentheses
// BEGIN closure_with_braces_outside_parentheses
var numbersSortedReversedAgain = numbers.sort {
    $0 > $1
} // = [120, 56, 32, 13, 2, 1]
// END closure_with_braces_outside_parentheses

// The line breaks are also optional.
// BEGIN closure_with_braces_outside_parentheses_no_newlines
var numbersSortedReversedOneMoreTime = numbers.sort { $0 > $1 }
// = [120, 56, 32, 13, 2, 1]
// END closure_with_braces_outside_parentheses_no_newlines



// Closures can be stored in variables and used like functions
// BEGIN closure_stored_in_variable_and_called_like_function
var comparator = {(a: Int, b:Int) in a < b}
comparator(1,2) // = true
// END closure_stored_in_variable_and_called_like_function

// BEGIN sorting_inline
var sortingInline = [2, 5, 98, 2, 13]
sortingInline.sort() // = [2, 2, 5, 13, 98]
// END sorting_inline

// ------
// Objects


// Classes define the 'blueprint' for an object
// BEGIN defining_class
class Vehicle {
    
    // BEGIN properties_in_class
    var color: String?
    var maxSpeed = 80
    // END properties_in_class
    
    // BEGIN functions_in_class
    func description() -> String {
        return "A \(self.color) vehicle"
    }
    
    func travel() {
        print("Traveling at \(maxSpeed) kph")
    }
    // END functions_in_class
}
// END defining_class

// BEGIN using_class
var redVehicle = Vehicle()
redVehicle.color = "Red"
redVehicle.maxSpeed = 90
redVehicle.travel() // prints "Traveling at 90 kph"
redVehicle.description() // = "A Red vehicle"
// END using_class

// ------
// Inheritance

// Classes can inherit from other classes

// BEGIN inheritance
class Car: Vehicle {
    
    var engineType : String = "V8"
    
    // BEGIN overidden_function
    // Inherited classes can override functions
    override func description() -> String  {
        let description = super.description()
        return description + ", which is a car"
    }
    // END overidden_function
    
}

// END inheritance

// Classes have a special 'init' function
class Motorcycle : Vehicle {
    var manufacturer : String
    
    override func description() -> String  {
        return "A \(color) \(manufacturer) bike"
    }
    
    // By the end of the init function, all variables that are not optional must have a value
    init(manufacturer: String = "No-Name Brand™")  {
        self.manufacturer = manufacturer
        
        // The superclass' init function must be called after all properties defined in this subclass have a value
        super.init()
        
        self.color = "Blue"
        
    }
    
    // 'convenience' init functions let you set up default values, and must call the main init method first
    convenience init (colour : String) {
        self.init()
        self.color = colour
    }
}

var firstBike = Motorcycle(manufacturer: "Yamaha")
firstBike.description() // = "A Blue Yamaha bike"

var secondBike = Motorcycle(colour: "Red")
secondBike.description() // = "A Red No-Name Brand™ bike"

// ------
// Properties

// Properties can be simple stored variables
// BEGIN property_example
class Counter {
    var number: Int = 0
}
let myCounter = Counter()
myCounter.number = 2
// END property_example

// Properties can be computed
// BEGIN computed_property
class Rectangle {
    var width: Double = 0.0
    var height: Double = 0.0
    var area : Double {
        // computed getter
        get {
            return width * height
        }
        
        // computed setter
        set {
            // Assume equal dimensions (i.e., a square)
            width = sqrt(newValue)
            height = sqrt(newValue)
        }
    }
}
// END computed_property

// BEGIN accessing_computed_property
var rect = Rectangle()
rect.width = 3.0
rect.height = 4.5
rect.area // = 13.5
rect.area = 9 // width & height now both 3.0
// END accessing_computed_property

// You can run code when a property changes
// BEGIN property_observer
class PropertyObserverExample {
    var number : Int = 0 {
        willSet(newNumber) {
            print("About to change to \(newNumber)")
        }
        didSet(oldNumber) {
            print("Just changed from \(oldNumber) to \(self.number)!")
        }
    }
}
// END property_observer

// BEGIN property_observer_example
var observer = PropertyObserverExample()
observer.number = 4
// prints "About to change to 4", then "Just changed from 0 to 4!"

// END property_observer_example

// Properties can be made 'lazy': they aren't set up until they're first called

// BEGIN lazy_property
class SomeExpensiveClass {
    init(id : Int) {
        print("Expensive class \(id) created!")
    }
}

class LazyPropertyExample {
    var expensiveClass1 = SomeExpensiveClass(id: 1)
    // note that we're actually constructing a class,
    // but it's labeled as lazy
    lazy var expensiveClass2 = SomeExpensiveClass(id: 2)
    
    
    init() {
        print("First class created!")
    }
}

var lazyExample = LazyPropertyExample()
// prints "Expensive class 1 created", then "First class created!"

lazyExample.expensiveClass1 // prints nothing, it's already created
lazyExample.expensiveClass2 // prints "Expensive class 2 created!"
// END lazy_property


// ------
// Protocols

// Protocols are lists of methods and properties that classes can contain


// BEGIN protocols
protocol Blinking {
    
    // This property must be (at least) gettable
    var isBlinking : Bool { get }
    
    // This property must be gettable and settable
    var blinkSpeed: Double { get set }
    
    // This function must exist, but what it does is up to the implementor
    func startBlinking(blinkSpeed: Double) -> Void
}
// END protocols

// BEGIN conforming_to_protocol
class TrafficLight : Blinking {
    var isBlinking: Bool = false
    
    var blinkSpeed : Double = 0.0
    
    func startBlinking(blinkSpeed : Double) {
        print("I am a traffic light, and I am now blinking")
        isBlinking = true
        
        // We say "self.blinkSpeed" here, as opposed to "blinkSpeed",
        // to help the compiler tell the difference between the
        // parameter 'blinkSpeed' and the property
        self.blinkSpeed = blinkSpeed
    }
}

class Lighthouse : Blinking {
    var isBlinking: Bool = false
    
    var blinkSpeed : Double = 0.0
    
    func startBlinking(blinkSpeed : Double) {
        print("I am a lighthouse, and I am now blinking")
        isBlinking = true
        
        self.blinkSpeed = blinkSpeed
    }
}
// END conforming_to_protocol

// BEGIN protocol_type
var aBlinkingThing : Blinking
// can be ANY object that has the Blinking protocol

aBlinkingThing = TrafficLight()

aBlinkingThing.startBlinking(4.0) // prints "I am now blinking"
aBlinkingThing.blinkSpeed // = 4.0

aBlinkingThing = Lighthouse()
// END protocol_type

// ------
// Extensions

// Types can be extended to include new properties and methods

// BEGIN extending_int
extension Int {
    var doubled : Int {
        return self * 2
    }
    func multiplyWith(anotherNumber: Int) -> Int {
        return self * anotherNumber
    }
}
// END extending_int

// BEGIN using_int_extension
2.doubled // = 4
4.multiplyWith(32) // = 128
// END using_int_extension


// Types can also be made to conform to a protocol
// BEGIN extending_with_protocol
extension Int : Blinking {
    var isBlinking : Bool {
        return false;
    }
    
    var blinkSpeed : Double {
        get {
            return 0.0;
        }
        set {
            // Do nothing
        }
    }
    
    func startBlinking(blinkSpeed : Double) {
        print("I am the integer \(self). I do not blink.")
    }
}
2.isBlinking // = false
2.startBlinking(2.0) // prints "I am the integer 2. I do not blink."
// END extending_with_protocol

// Access control

// This class is visible to everyone

// BEGIN access_control_class
public class AccessControl {
    
    // BEGIN internal_property
    // Accessible to this module only
    // 'internal' here is the default and can be omitted
    internal var internalProperty = 123
    // END internal_property
    
    // BEGIN public_property
    // Accessible to everyone
    public var publicProperty = 123
    // END public_property
    
    // BEGIN private_property
    // Only accessible in this source file
    private var privateProperty = 123
    // END private_property
    
    // BEGIN private_setter_property
    // The setter is private, so other files can't modify it
    private(set) var privateSetterProperty = 123
    // END private_setter_property
}
// END access_control_class


// ------
// Interoperating with Objective-C

// Creating Objective-C objects
// BEGIN creating_objc_object
var view = UIView(frame: CGRect(x: 0,y: 0,width: 100,height: 100))
// END creating_objc_object

// Working with Objective-C properties
// BEGIN objc_property
view.bounds
// END objc_property

// Calling Objective-C methods
// BEGIN objc_method
view.pointInside(CGPoint(x: 20, y: 20), withEvent:nil) // = true
// END objc_method

// ------
// Modules

// BEGIN modules
import AVFoundation
// END modules

// ------
// Memory Management

// References to other classes are strong, but can be made explicitly weak
// BEGIN weak_reference
class Class1 {
    init() {
        print("Class 1 being created!")
    }
    
    deinit {
        print("Class 1 going away!")
    }
}

class Class2 {
    // Weak vars are implicitly optional
    weak var weakRef : Class1?
}
// END weak_reference

// ------
// Initialization and Deinitialisation

// BEGIN init_and_deinit
class InitAndDeinitExample {
    // Designated (i.e., main) initializer
    init () {
        print("I've been created!")
    }
    // Convenience initializer, required to call the
    // designated initializer (above)
    convenience init (text: String) {
        self.init() // this is mandatory
        print("I was called with the convenience initializer!")
    }
    // Deinitializer
    deinit {
        print("I'm going away!")
    }
}

var example : InitAndDeinitExample?

// using the designated initializer
example = InitAndDeinitExample() // prints "I've been created!"
example = nil // prints "I'm going away"

// using the convenience initializer
example = InitAndDeinitExample(text: "Hello")
// prints "I've been created!" and then
//  "I was called with the convenience initializer"
// END init_and_deinit

extension InitAndDeinitExample {
    
    // BEGIN init_failable
    // This is a convenience initializer that can sometimes fail, returning nil
    // Note the ? after the word 'init'
    convenience init? (value: Int) {
        self.init()
        
        if value > 5 {
            // We can't initialize this object; return nil to indicate failure
            return nil
        }
        
    }
    // END init_failable
    
}

// BEGIN init_failable_example
var failableExample = InitAndDeinitExample(value: 6)
// = nil
// END init_failable_example

// ------
// Mutable and Immutable Objects

var mutableString = ""
let immutableString = "Yes"

mutableString += "Internet"
// immutableString += "Hello"
// ERROR: Can't modify an immutable object


// ------
// Working with Strings

// Strings can be empty
// BEGIN empty_string_1
let emptyString = ""
// END empty_string_1

// BEGIN empty_string_2
let anotherEmptyString = String()
// END empty_string_2

// You can check to see if a string is empty

// BEGIN checking_empty_string
emptyString.isEmpty // = true
// END checking_empty_string

// You can add strings together
// BEGIN composing_string
var composingAString = "Hello"
composingAString += ", World!" // = "Hello, World!"
// END composing_string

// You can loop over a string's characters
// BEGIN looping_over_string_contents
var reversedString = ""
for character in "Hello".characters {
    reversedString = String(character) + reversedString
}
reversedString // = "olleH"
// END looping_over_string_contents

// You can get the number of characters in a string
// BEGIN counting_elements_in_string
"Hello".characters.count // = 5
// END counting_elements_in_string


// ------
// Comparing Strings

// Compare to see if two strings are the same text using ==
// BEGIN compare_two_strings
let string1 : String = "Hello"
let string2 : String = "Hel" + "lo"

if string1 == string2 {
    print("The strings are equal")
}
// END compare_two_strings

// Compare to see if two strings are the same object with ===
// BEGIN compare_strings_same_object
if string1 as AnyObject === string2 as AnyObject {
    print("The strings are the same object")
}
// END compare_strings_same_object

// Check to see if a string has a certain suffix or prefix
// BEGIN string_prefix_and_suffix
if string1.hasPrefix("H") {
    print("String begins with an H")
}
if string1.hasSuffix("llo") {
    print("String ends in 'llo'")
}
// END string_prefix_and_suffix

var i : Int? = 2

2 + i!


// Converting a string to uppercase and lowercase
// BEGIN string_case_changing
string1.uppercaseString // = "HELLO"
string2.lowercaseString // = "hello"
// END string_case_changing
// ------
// Searching Strings

// NOTE: NOT SURE ABOUT THIS. SEEMS WEIRD.


// ------
// NSValue and NSNumber

// NSValues and NSNumbers contain values and numbers
var anNSNumber : NSNumber = 2
var aNumber = 3
aNumber + anNSNumber.integerValue


// ------
// Data

// BEGIN string_to_data
let stringToConvert = "Hello, Swift"
let data = stringToConvert.dataUsingEncoding(NSUTF8StringEncoding)
// END string_to_data

// ------
// Loading Data from Files and URLs

// BEGIN loading_data_from_files
// Loading from URL
if let URL = NSURL(string: "https://oreilly.com") {
    let loadedDataFromURL = NSData(contentsOfURL:URL)
}

// Loading from a file
if let filePath = NSBundle.mainBundle()
    .pathForResource("SomeFile", ofType: "txt") {
        let loadedDataFromPath = NSData(contentsOfFile:filePath)
}
// END loading_data_from_files

// ------
// Serialization and Deserialization

// BEGIN serializable_object
class SerializableObject : NSObject, NSCoding {
    
    var name : String?
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(name!, forKey:"name")
    }
    override init() {
        self.name = "My Object"
    }
    required init(coder aDecoder: NSCoder)  {
        self.name = aDecoder.decodeObjectForKey("name") as? String
    }
}
// END serializable_object

// BEGIN serializing_an_object
let anObject = SerializableObject()

anObject.name = "My Thing That I'm Saving"

// Converting it to data
let objectConvertedToData =
NSKeyedArchiver.archivedDataWithRootObject(anObject)

// Converting it back
// Note that the conversion might fail, so 'unarchiveObjectWithData' returns
// an optional value. So, use 'as?' to check to see if it worked.
let loadedObject =
NSKeyedUnarchiver.unarchiveObjectWithData(objectConvertedToData)
    as? SerializableObject

loadedObject?.name
// = "My Thing That I'm Saving"
// END serializing_an_object

// ------
// Delegation

// BEGIN delegate_example
// Define a protocol that has a function called handleIntruder
protocol HouseSecurityDelegate {
    
    // We don't define the function here, but rather
    // indicate that any class that is a HouseSecurityDelegate
    // is required to have a handleIntruder() function
    func handleIntruder()
}

class House {
    // The delegate can be any object that conforms to the HouseSecurityDelegate
    // protocol
    var delegate : HouseSecurityDelegate?
    
    func burglarDetected() {
        // Check to see if the delegate is there, then call it
        delegate?.handleIntruder()
    }
}

class GuardDog : HouseSecurityDelegate {
    func handleIntruder() {
        print("Releasing the hounds!")
    }
}


let myHouse = House()
myHouse.burglarDetected() // does nothing

let theHounds = GuardDog()
myHouse.delegate = theHounds
myHouse.burglarDetected() // prints "Releasing the hounds!"
// END delegate_example


// ------
// Key-Value Observing

class Boat : NSObject {
    var colour = 1
}
/*
class ObservingClass : NSObject {
func observeObject(theObject : NSObject) {
theObject.addObserver(self, forKeyPath: "colour", options: NSKeyValueObservingOptions.New | NSKeyValueObservingOptions.Old, context: nil)
}

override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [NSObject : AnyObject]!, context: UnsafePointer<()>) {

var theChange = change as [String : String]

var oldColour = theChange[NSKeyValueChangeOldKey] as String
var newColour = theChange[NSKeyValueChangeNewKey] as String

print("Colour changed from \(oldColour) to \(newColour)")

}
}

var aNewBoat = Boat()
aNewBoat.colour = 2

var observerObject = ObservingClass()
observerObject.observeObject(aNewBoat) // NOTE: this appears to be throwing some kind of exception, will revisit later

*/

// Swift and Objective-C

// BEGIN swift_and_objc
@objc class Cat : NSObject {
    var name : String = ""
    
    func speak() -> String {
        return "Meow"
    }
}
// END swift_and_objc

/*
// This example is commented out because it calls itself infinitely recursively,
// which is not a great thing.
// BEGIN operator_example
func + (left: Int, right: Int) -> Int {
    return left + right
}
// END operator_example
*/

// BEGIN operators_class
class Vector2D {
    var x : Float = 0.0
    var y : Float = 0.0
    
    init (x : Float, y: Float) {
        self.x = x
        self.y = y
    }
}
// END operators_class

// BEGIN operators_overload
func +(left : Vector2D, right: Vector2D) -> Vector2D {
    let result = Vector2D(x: left.x + right.x, y: left.y + right.y)
    
    return result
}
// END operators_overload

// BEGIN operators_usage
let first = Vector2D(x: 2, y: 2)
let second = Vector2D(x: 4, y: 1)

let result = first + second
// = (x:6, y:3)
// END operators_usage

// BEGIN generics_example
class Tree <T> {
    
    // 'T' can now be used as a type inside this class
    
    // 'value' is of type T
    var value : T
    
    // 'children' is an array of Tree objects that have 
    // the same type as this one
    private (set) var children : [Tree <T>] = []
    
    // We can initialise this object with a value of type T
    init(value : T) {
        self.value = value
    }
    
    // And we can add a child node to our list of children
    func addChild(value : T) -> Tree <T> {
        let newChild = Tree<T>(value: value)
        children.append(newChild)
        return newChild
    }
}
// END generics_example

// BEGIN generics_usage
// Tree of integers
let integerTree = Tree<Int>(value: 5)

// Can add children that contain Ints
integerTree.addChild(10)
integerTree.addChild(5)

// Tree of strings
let stringTree = Tree<String>(value: "Hello")

stringTree.addChild("Yes")
stringTree.addChild("Internets")
// END generics_usage

// BEGIN enumeration_example

// enumeration of top secret future iPads that definitely
// will never exist
enum FutureiPad {
    case iPadSuperPro
    
    case iPadTotallyPro
    
    case iPadLudicrous
}
// END enumeration_example


// BEGIN enumeration_using

var nextiPad = FutureiPad.iPadTotallyPro

// END enumeration_using


// BEGIN enumeration_example_setting

nextiPad = .iPadSuperPro

// END enumeration_example_setting

// BEGIN enumeration_switch

switch nextiPad {
case .iPadSuperPro:
    print("Too big!")
    
case .iPadTotallyPro:
    print("Too small!")
    
case .iPadLudicrous:
    print("Just right!")
}

// END enumeration_switch

// BEGIN enumeration_switch_2

switch nextiPad {
case .iPadSuperPro:
    print("Very large iPad!")
    
default:
    print("Way too big.")
}
// END enumeration_switch_2

/*
// BEGIN enumeration_associated_values_1
enum Weapon {
    case Laser
    case Missiles
}
// END enumeration_associated_values_1
*/

// BEGIN enumeration_associated_values_2
enum Weapon {
    case Laser(powerLevel: Int)
    case Missiles(range: Int)
}
// END enumeration_associated_values_2

// BEGIN enumeration_associated_values_usage
let spaceLaser = Weapon.Laser(powerLevel: 5)
// END enumeration_associated_values_usage

// BEGIN enumeration_associated_values_usage_switch
switch spaceLaser {
case .Laser(powerLevel: 0...10 ):
    print("It's a laser with power from 0 to 10!")
case .Laser:
    print("It's a laser!")
case .Missiles(let range):
    print("It's a missile with range \(range)!")
}
// Prints "It's a laser with power from 0 to 10!"
// END enumeration_associated_values_usage_switch

/*
// BEGIN set_example
var setOfStrings = Set<String>()
// END set_example
*/

// BEGIN set_example_2
var fruitSet: Set = ["apple", "orange", "orange", "banana"]
// END set_example_2

// BEGIN set_example_count
fruitSet.count
// = 3
// END set_example_count

// BEGIN set_operations
if fruitSet.isEmpty {
    print("My set is empty!")
}

// Add a new item to the set
fruitSet.insert("pear")

// Remove an item from the set
fruitSet.remove("apple")
// mySet now contains {"banana", "pear", "orange"}
// END set_operations

// BEGIN set_iteration
for fruit in fruitSet {
    let fruitPlural = fruit + "s"
    print("You know what's tasty? \(fruitPlural.uppercaseString).")
}
// END set_iteration

// BEGIN error_handling_example

// TODO error handling example goes here

// END error_handling_example

// BEGIN subscript_example
// Extend the unsigned 8-bit integer type
extension UInt8 {
    
    // Allow subscripting this type using UInt8s;
    subscript(bit: UInt8) -> UInt8 {
        
        // This is run when you do things like "value[x]"
        get {
            return (self >> bit & 0x07) & 1
        }
        
        // This is run when you do things like "value[x] = y"
        set {
            let cleanBit = bit & 0x07
            let mask = 0xFF ^ (1 << cleanBit)
            let shiftedBit = (newValue & 1) << cleanBit
            self = self & mask | shiftedBit
        }
    }
}
// END subscript_example

// BEGIN subscript_example_using
var byte : UInt8 = 212

byte[0] // 0
byte[2] // 1
byte[5] // 0
byte[6] // 1

// Change the last bit
byte[7] = 0

// The number is now changed!
byte // = 84
// END subscript_example_using

// BEGIN structures_example
struct Point {
    var x: Int
    var y: Int
}
// END structures_example

// BEGIN structures_default_initialiser
let p = Point(x: 2, y: 3)
// END structures_default_initialiser

// BEGIN error_enum
enum BankError : ErrorType {
    // Not enough money in the account
    case NotEnoughFunds
    
    // Can't create an account with negative money
    case CannotBeginWithNegativeFunds
    
    // Can't make a negative deposit or withdrawal
    case CannotMakeNegativeTransaction(amount:Float)
}
// END error_enum

// BEGIN error_example_throwing
// A simple bank account class.
class BankAccount {
    
    // The amount of money in the account.
    private (set) var balance : Float = 0.0
    
    // Initialises the account with an amount of money.
    // Throws an error if you try to create the account
    // with negative funds.
    init(amount:Float) throws {
        
        // Ensure that we have a non-negative amount of money
        guard amount > 0 else {
            throw BankError.CannotBeginWithNegativeFunds
        }
        balance = amount
    }
    
    // Adds some money to the account.
    func deposit(amount: Float) throws {
        
        // Ensure that we're trying to deposit a non-negative amount
        guard amount > 0 else {
            throw BankError.CannotMakeNegativeTransaction(amount: amount)
        }
        balance += amount
    }
    
    // Withdraws money from the bank account.
    func withdraw(amount : Float) throws {
        
        // Ensure that we're trying to deposit a non-negative amount
        guard amount > 0 else {
            throw BankError.CannotMakeNegativeTransaction(amount: amount)
        }
        
        // Ensure that we have enough to withdraw this amount
        guard balance >= amount else {
            throw BankError.NotEnoughFunds
        }
        
        balance -= amount
    }
}
// END error_example_throwing

// BEGIN error_example_usage
do {
    let vacationFund = try BankAccount(amount: 5)
    
    try vacationFund.deposit(5)
    
    try vacationFund.withdraw(11)
    
} catch let error as BankError {
    
    // Catch any BankError that was thrown
    switch (error) {
    case .NotEnoughFunds:
        print("Not enough funds in account!")
    case .CannotBeginWithNegativeFunds:
        print("Tried to start an account with negative money!")
    case .CannotMakeNegativeTransaction(let amount):
        print("Tried to do a transaction with a negative amount of \(amount)!")
    }
    
} catch let error {
    // (Optional:) catch other types of errors
}
// END error_example_usage

// BEGIN error_example_usage_try?
let secretBankAccountOrNot = try? BankAccount(amount: -50) // = nil
// END error_example_usage_try?

/*
// BEGIN error_example_usage_try!
let secretBankAccountOrNot = try! BankAccount(amount: -50) // crash!
// END error_example_usage_try!
*/

/*
// This section is commented out because it relies on code that would normally
// be distributed across multiple files. We've included here in one place
// for convenience.

// BEGIN swift_and_objc_header
#import "MyAppName-Swift.h"
// END swift_and_objc_header

// BEGIN swift_and_objc_using
Cat* myCat = [[Cat alloc] init];
myCat.name = "Fluffy";
[myCat speak];
// END swift_and_objc_using


// BEGIN objc_and_swift
@interface Elevator

- (void) moveUp;
- (void) moveDown;

@property NSString* modelName;

@end
// END objc_and_swift

// BEGIN objc_and_swift_bridging_header
#import "Elevator.h"
// END objc_and_swift_bridging_header

// BEGIN objc_and_swift_using
let theElevator = Elevator()

theElevator.moveUp()
theElevator.moveDown()

theElevator.modelName = "The Great Glass Elevator"
// END objc_and_swift_using

*/


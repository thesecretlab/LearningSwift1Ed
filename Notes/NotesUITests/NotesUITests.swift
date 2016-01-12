//
//  NotesUITests.swift
//  NotesUITests
//
//  Created by Jonathon Manning on 24/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import XCTest

@available(OSX 10.11, *)
class NotesUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        
        super.tearDown()
    }
    
    // BEGIN ui_test
    func testCreatingSavingAndClosingDocument() {
        
        // Get the app
        let app = XCUIApplication()
        
        // Choose File->New
        let menuBarsQuery = XCUIApplication().menuBars
        menuBarsQuery.menuBarItems["File"].click()
        menuBarsQuery.menuItems["New"].click()
        
        // Get the new 'Untitled' window
        let untitledWindow = app.windows["Untitled"]
        
        // Get the main text view
        let textView = untitledWindow.childrenMatchingType(.ScrollView).elementBoundByIndex(0).childrenMatchingType(.TextView).element
        
        // Type some text
        textView.typeText("This is a useful document that I'm testing.")
        
        // Save it by pressing Command-S
        textView.typeKey("s", modifierFlags:.Command)
        
        // The save sheet has appeared; type "Test" in it and press return
        untitledWindow.sheets["save"].childrenMatchingType(.TextField).elementBoundByIndex(0).typeText("Test\r")
        
        // Close the document
        app.windows["Test"].typeKey("w", modifierFlags:.Command)
    }
    // END ui_test
    
}

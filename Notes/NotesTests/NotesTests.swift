//
//  NotesTests.swift
//  NotesTests
//
//  Created by Jonathon Manning on 24/08/2015.
//  Copyright © 2015 Jonathon Manning. All rights reserved.
//

import XCTest
@testable import Notes


class NotesTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Setup code goes here
    }
    
    override func tearDown() {
        
        // Teardown code goes here
        super.tearDown()
    }
    
    // BEGIN unit_test
    func testDocumentTypeDetection() {

        // Create an NSFileWrapper using some empty data
        let data = NSData()
        let document = NSFileWrapper(regularFileWithContents: data)
        
        // Give it a name
        document.preferredFilename = "Hello.jpg"
        
        // It should now think that it's an image
        XCTAssertTrue(document.conformsToType(kUTTypeImage))

    }
    // END unit_test

    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}

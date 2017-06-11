//
//  PathTests.swift
//  NeverthelessTests
//
//  Created by Ben Gottlieb on 6/11/17.
//  Copyright © 2017 Ben Gottlieb. All rights reserved.
//

import XCTest
import Nevertheless

struct StorageTest: Codable, Equatable {
	let integer: Int
	let string: String
	
	static func ==(lhs: StorageTest, rhs: StorageTest) -> Bool {
		return lhs.integer == rhs.integer && lhs.string == rhs.string
	}
}

class PathTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testStorageAtPath() {
		let test = StorageTest(integer: 7, string: "hello")
		Path.documents["encoded.test"] = test
		
		let decoded: StorageTest? = Path.documents["encoded.test"]
		
		XCTAssert(decoded == test, "Failed to extract an identical object")
		
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
	
	func testCreatePath() {
		let base = Path.documents
		let created = base.child("sub/path")
		let dest = created.child("test.dat")
		
		try? dest.remove()
		XCTAssert(!dest.exists, "Failed to delete file")
		created["test.dat"] = StorageTest(integer: 4, string: "test")
		XCTAssert(dest.exists, "Failed to create file")
		
		try? created.parent?.remove()
		XCTAssert(!created.exists, "Failed to delete directory")
	}
    
}

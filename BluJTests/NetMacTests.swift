//
//  NetMacTests.swift
//  BluJTests
//
//  Created by Lavergne, Marc on 3/27/20.
//  Copyright © 2020 Lavergne, Marc. All rights reserved.
//

import XCTest
@testable import BluJ

class NetMacTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testGetRoutes() {
        print(NetworkMac.getRoutes())
    }

    func testGetLANRoutes() {
        print(NetworkMac.getLANRoutes())
    }

    func testGetDefaultLANRoute() {
        print(NetworkMac.getDefaultLANRoute())
    }

    func testGetDefaultRoute() {
        print(NetworkMac.getDefaultRoute())
    }
    
    func testGetRoute() {
        print(NetworkMac.getRoute("192.168.1.238"))
    }
}

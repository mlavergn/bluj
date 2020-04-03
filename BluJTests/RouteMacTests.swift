//
//  RouteMacTests.swift
//  BluJTests
//
//  Created by Lavergne, Marc on 3/26/20.
//  Copyright © 2020 Lavergne, Marc. All rights reserved.
//

import XCTest
@testable import BluJ

class RouteMacTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testGetRoutes() {
        print(RouteMac.getRoutes())
    }

    func testGetDefaultRoute() {
        print(RouteMac.getDefaultRoute())
    }
    
    func testAddRoute() {
        print(isRoot())
        print(RouteMac.addRoute(destination: "13.251.83.128", gateway: "192.168.1.1", interface: "en0"))
    }
}

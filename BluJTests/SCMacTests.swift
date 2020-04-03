//
//  SCMacTests.swift
//  BluJTests
//
//  Created by Lavergne, Marc on 3/25/20.
//  Copyright © 2020 Lavergne, Marc. All rights reserved.
//

import XCTest
@testable import BluJ

class SCMacTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSetDNS() {
        print(NetworkInfoSC.setDNS())
    }

    func testVPNEnabled() {
        print(NetworkInfoSC.vpnEnabled())
    }

    func testLanGateway() {
        print(NetworkInfoSC.lanGateway())
    }
    
    func testNetworkInterfaces() {
        print(NetworkInfoSC.networkInterfaces())
    }

    func testNetworkInterfaceMap() {
        print(NetworkInfoSC.networkInterfaceMap())
    }
}

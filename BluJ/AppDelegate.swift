//
//  AppDelegate.swift
//  BluJ
//
//  Created by Lavergne, Marc on 3/25/20.
//  Copyright © 2020 Lavergne, Marc. All rights reserved.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let bluj = BluJUI()
        bluj.run()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
}

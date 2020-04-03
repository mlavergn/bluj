//
//  main.swift
//  BluJ
//
//  Created by Lavergne, Marc on 3/25/20.
//  Copyright © 2020 Lavergne, Marc. All rights reserved.
//

import Cocoa
import os.log

func isUnitTest() -> Bool {
    return NSClassFromString("XCTest") != nil
}

func isRoot() -> Bool {
    return NSUserName() == "root"
}

func main() {
    let delegate = AppDelegate()
    NSApplication.shared.delegate = delegate

    os_log("Launch %{public}@", log: OSLog.blu.main, type: .info, CommandLine.arguments)

    // unit tests will try to launch main, so  bypass priviledge escalation
    if isUnitTest() || isRoot() || (CommandLine.argc > 1 && CommandLine.arguments[1] == "admin") {
        os_log("Launched as administrator, rendering UI", log: OSLog.blu.main, type: .info)
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
        return
    }

    os_log("Relaunch as administrator", log: OSLog.blu.main, type: .info)
    _ = AdminMac.run(CommandLine.arguments[0], args: ["admin"])
}

main()

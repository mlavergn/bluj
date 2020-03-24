//
//  main.swift
//  BluJ
//
//  Created by Lavergne, Marc on 3/25/20.
//  Copyright © 2020 Lavergne, Marc. All rights reserved.
//

import Cocoa
import os.log

public class BluJLog {
    static let logSubsystem = "com.marclavergne.BluJ"
    lazy var admin = OSLog(subsystem: BluJLog.logSubsystem, category: "admin")
}

extension OSLog {
    public static let bluj = BluJLog()
}

func main() {
    let delegate = AppDelegate()
    NSApplication.shared.delegate = delegate

    os_log("Launch %{public}@", log: OSLog.bluj.admin, type: .info, CommandLine.arguments)
    print(CommandLine.arguments)
    if CommandLine.argc > 1 && CommandLine.arguments[1] == "admin" {
        os_log("Launched as admin, render menu", log: OSLog.bluj.admin, type: .info)
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
        return
    }

    os_log("Relaunch as admin", log: OSLog.bluj.admin, type: .info)
    _ = AdminMac.run(CommandLine.arguments[0], args: ["admin"])
}

main()

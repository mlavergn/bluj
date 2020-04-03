//
//  BluLog.swift
//  BluJ
//
//  Created by Lavergne, Marc on 3/26/20.
//  Copyright © 2020 Lavergne, Marc. All rights reserved.
//

import Foundation
import os.log

public class BluLog {
    static let logSubsystem = "com.marclavergne.BluJ"
    lazy var main = OSLog(subsystem: BluLog.logSubsystem, category: "main")
}

extension OSLog {
    public static let blu = BluLog()
}

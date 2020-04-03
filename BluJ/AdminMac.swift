//
//  AdminMac.swift
//  BluJ
//
//  Created by Lavergne, Marc on 3/24/20.
//  Copyright © 2020 Lavergne, Marc. All rights reserved.
//

import Foundation
import Security
import os

public class AdminMacLog {
    static let logSubsystem = "com.marclavergne.AdminMac"
    lazy var log = OSLog(subsystem: AdminMacLog.logSubsystem, category: "admin")
}

extension OSLog {
    public static let admin = AdminMacLog()
}

class AdminMac {
    static func run(_ executable: String, args: [String]) -> OSStatus {
        guard let authorizationRef = AdminMac.create() else {
            return errAuthorizationSuccess
        }
        var status = check(authorizationRef)
        if status != errAuthorizationSuccess {
            return status
        }
        status = AdminMac.execute(authorizationRef, executable: executable, args: args)
        AdminMac.free(authorizationRef)
        return status
    }

    static func create() -> AuthorizationRef? {
        var authorizationRef: AuthorizationRef?
        let status = AuthorizationCreate(nil, nil, AuthorizationFlags(rawValue: 0), &authorizationRef)
        if status != errAuthorizationSuccess {
            print("failed to create auth request")
            return nil
        }
        return authorizationRef
    }

    static func check(_ authorizationRef: AuthorizationRef) -> OSStatus {
        var right = AuthorizationItem(name: kAuthorizationRightExecute, valueLength: 0, value: nil, flags: 0)
        var rights = AuthorizationRights(count: 1, items: &right)
        let flags = AuthorizationFlags(rawValue: 0 | AuthorizationFlags.interactionAllowed.rawValue | AuthorizationFlags.preAuthorize.rawValue | AuthorizationFlags.extendRights.rawValue)
        let status = AuthorizationCopyRights(authorizationRef, &rights, nil, flags, nil)
        if (status != errAuthorizationSuccess) {
            print("failed to prepare execute request");
        }
        return status;
    }
    
    /// Fallback to ObjC here since AuthorizationExecuteWithPrivileges is not exposed to Swift
    static func execute(_ authorizationRef: AuthorizationRef, executable: String, args: [String]) -> OSStatus {
        AuthExec.execute(authorizationRef, executable: executable, args: args)
    }

    static func free(_ authorizationRef: AuthorizationRef) {
        AuthorizationFree(authorizationRef, .destroyRights)
    }
}

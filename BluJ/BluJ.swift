//
//  BluJ.swift
//  BluJ
//
//  Created by Lavergne, Marc on 3/24/20.
//  Copyright © 2020 Lavergne, Marc. All rights reserved.
//

import Foundation

let hostsText = """
199.48.152.0/22
31.171.208.0/21
103.20.59.0/24
103.255.54.0/24
8.10.12.0/24
165.254.117.0/24
13.210.3.128/26
34.245.240.192/26
13.251.83.128/26
104.238.240.0/21
34.223.12.128/26
35.175.114.0/26
52.215.218.0/26
13.233.177.128/26
44.234.22.192/26
18.141.148.64/26
3.25.41.0/26
3.6.70.192/26
"""

class BluJ : NetworkMac {
    let hosts: [String]
    
    override init() {
        let hostLines = hostsText.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\n")
        self.hosts = hostLines.map { line in
            return String(line)
        }
    }
    
    func setBluejeansRoutes(_ ifc: NetworkInterface) {
        _ = hosts.map { host in
            addRoute(ipSeg: host, gateway: ifc.gateway)
        }
    }
    
    func getBluejeansGateway() -> NetworkInterface? {
        var testHost: String?
        for host in hosts {
            if !host.contains(".0/") {
                testHost = host
                break
            }
        }
        
        guard let blujHost = testHost else {
            return nil
        }

        return getGateway(ipSeg: blujHost)
    }
    
    func isBluejeansRouteLAN() -> Bool {
        let ifc = getBluejeansGateway()
        let lan = getDefaultGateway()
        return ifc?.gateway == lan?.gateway
    }
}

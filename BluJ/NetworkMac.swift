//
//  NetworkMac.swift
//  BluJ
//
//  Created by Lavergne, Marc on 3/23/20.
//  Copyright © 2020 Lavergne, Marc. All rights reserved.
//

import Foundation
import SystemConfiguration

struct OSTask {
    var executable: String
    var arguments: [String]
}

class NetworkMac {
    func GetRoutes() -> [String: NetworkInterface] {
        let task = OSTask(executable: "/usr/sbin/netstat", arguments: ["-nr", "-f", "inet"])
        let (output, error) = self.run(ostask: task)
        print(output, error)

        var skip = true
        let lines = parseLines(output).filter { line in
            if skip {
                if line.hasPrefix("Destination") {
                    skip = false
                }
                return false
            }
            return true
        }
        let fieldSet = parseFieldSet(lines, " ")
                
        var ifcs: [NetworkInterface] = fieldSet.map { fields in
            var ifc = NetworkInterface(ifcName: "", ipAddr: "", gateway: "")
            for (i, val) in fields.enumerated() {
                switch i {
                case 0:
                    ifc.ipAddr = val
                case 1:
                    ifc.gateway = val
                case 2:
                    ifc.ifcName = val
                default:
                    break
                }
            }
            return ifc
        }
        
        ifcs = ifcs.filter { ifc in
            !ifc.ipAddr.contains(":")
        }
        
        var result: [String: NetworkInterface] = [:]
        for ifc in ifcs {
            result[ifc.ipAddr] = ifc
        }
        return result
    }
   
    /// Route a given ip segment via a specific gateway
    ///  NOTE: Will fail if not called as an administrator
    /// - Parameters:
    ///   - ipSeg: ip address segment to route
    ///   - gateway: ip gateway to route over
    func addRoute(ipSeg: String, gateway: String) {
        let task = OSTask(executable: "/sbin/route", arguments: ["-n", "add", ipSeg, gateway])
        _ = self.run(ostask: task)
    }

    /// Reset the route via DHCP for the supplied interface
    ///  NOTE: Will fail if not called as an administrator
    /// - Parameters:
    ///   - ifc: interface BSD name to reset
    func resetRoute(ifc: NetworkInterface) {
        let task = OSTask(executable: "/usr/sbin/ipconfig", arguments: ["set", ifc.ifcName, "DHCP"])
        _ = self.run(ostask: task)
    }

    /// Get the gateway used for the given ip segment
    /// - Parameter ipSeg: ip address segment to query
    /// Returns NetworkInterface with details
    func getGateway(ipSeg: String) -> NetworkInterface? {
        let task = OSTask(executable: "/sbin/route", arguments: ["-n", "get", ipSeg])
        let (output, error) = self.run(ostask: task)
        print(output, error)

        let lines = parseLines(output)
        let fieldSet = parseFieldSet(lines, ":")
        for fields in fieldSet {
            if fields.count > 1 {
                if fields[0] == "gateway" {
                    return NetworkInterface(ifcName: "", ipAddr: ipSeg, gateway: fields[1])
                }
            }
        }
        
        return nil
    }

    /// Get the default system internet gateway
    func getDefaultGateway() -> NetworkInterface? {
        return getGateway(ipSeg: "default")
    }

    /// Get the default LAN internet gateway
    func getDefaultLAN() -> NetworkInterface? {
        let ifcs = getLanIPAddrs()
        let lan = ifcs.filter { ifc in
            ifc.ipAddr.contains(".") && ifc.ifcName.hasPrefix("en")
        }
        guard var result = lan.first else {
            return nil
        }
        result.gateway = getGateway(ipSeg: result.ipAddr)?.gateway ?? ""
        return result
    }

    func getLanIPAddrs() -> [NetworkInterface] {
        var result: [NetworkInterface] = []
        var ifAddrs: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifAddrs) == 0 else {
            return result
        }
        var pointer = ifAddrs
        while pointer != nil {
            defer { pointer = pointer?.pointee.ifa_next }
            guard let ifc = pointer?.pointee, ifc.ifa_addr.pointee.sa_family == UInt8(AF_INET),
                ifc.ifa_flags & UInt32(IFF_LOOPBACK) == 0, ifc.ifa_flags & UInt32(IFF_UP) != 0 else {
                continue
            }
            guard let ifcName = String(validatingUTF8: ifc.ifa_name) else {
                continue
            }
            var ipAddrRaw = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(ifc.ifa_addr, socklen_t(ifc.ifa_addr.pointee.sa_len), &ipAddrRaw, socklen_t(ipAddrRaw.count), nil, socklen_t(0), NI_NUMERICHOST)
            guard let ipAddr = String(validatingUTF8: ipAddrRaw) else {
                continue
            }
            result.append(NetworkInterface(ifcName: ifcName, ipAddr: ipAddr, gateway: ""))
        }
        freeifaddrs(ifAddrs)
        return result
    }

    // NOT USED
    func getLANFromSCN() -> [NetworkInterface] {
        let ifcRaw = SCNetworkInterfaceCopyAll() as [AnyObject]
        var ifcSCN: [SCNetworkInterface] = ifcRaw.map { ifc in
            return (ifc as! SCNetworkInterface)
        }
        
        // filter out non-Ethernet interfaces
        ifcSCN = ifcSCN.filter { ifc in
            return SCNetworkInterfaceGetInterfaceType(ifc) as String? == "Ethernet"
        }
        
        // filter out unnamed interfaces
        let ifcNIC: [NetworkInterface] = ifcSCN.map { ifc in
            let ifcName = SCNetworkInterfaceGetBSDName(ifc) as String? ?? ""
            return NetworkInterface(ifcName: ifcName, ipAddr: "", gateway: "")
        }

        return ifcNIC
    }
    
    //
    // MARK: - Parsing
    //
    
    /// Parse a block of text into trimmed lines
    /// - Parameter text: text to parse
    /// Returns [String]
    func parseLines(_ text: String) -> [String] {
        let lines = text.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\n")
        return lines.map { line in
            line.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /// Parse an array of lines into an array of fields
    /// - Parameters:
    ///   - lines: lines to parse
    ///   - delimiter: delimiter between fields (empty delimiters will not be counted as fields eg. multiple spaces)
    /// Returns [[String]]
    func parseFieldSet(_ lines: [String], _ delimiter: Character) -> [[String]] {
        return lines.map { line in
            let fields = line.split(separator: delimiter)
            return fields.map { field in
                field.trimmingCharacters(in: .whitespacesAndNewlines)
            }.filter { field in
                field.count > 0
            }
        }
    }

    //
    // MARK: - Tasks
    //
    
    /// <#Description#>
    /// - Parameter ostask: task definition to run
    /// Returns the stdout and stderr on completion
    func run(ostask: OSTask) -> (String, String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: ostask.executable)
        task.arguments = ostask.arguments
    
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        task.standardOutput = outputPipe
        task.standardError = errorPipe
        try? task.run()
    
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
    
        let output = String(decoding: outputData, as: UTF8.self)
        let error = String(decoding: errorData, as: UTF8.self)
        
        return (output, error)
    }
}

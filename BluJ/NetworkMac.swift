//
//  NetworkMac.swift
//  BluJ
//
//  Created by Lavergne, Marc on 3/23/20.
//  Copyright © 2020 Lavergne, Marc. All rights reserved.
//

import Foundation
import SystemConfiguration
import os

public class NetworkMacLog {
    static let logSubsystem = "com.marclavergne.NetworkMac"
    lazy var log = OSLog(subsystem: NetworkMacLog.logSubsystem, category: "network")
}

extension OSLog {
    public static let net = NetworkMacLog()
}

struct NetworkRoute: CustomDebugStringConvertible {
    var ifName: String
    var ipAddress: String
    var ipGateway: String
    var serviceId: String = ""
    
    func isVPN() -> Bool {
        return self.ifName.hasPrefix("utun")
    }
    
    var debugDescription: String {
        return "\(ifName): \(ipAddress) -> \(ipGateway)"
    }
}

struct Task {
    var executable: String
    var arguments: [String]
}

class NetworkMac {
    
    /// Get the current routing table
    /// netstat -nr -f inet
    static func getRoutes() -> [String: NetworkRoute] {
        let task = Task(executable: "/usr/sbin/netstat", arguments: ["-nr", "-f", "inet"])
        let (output, error) = self.run(task)
        if error != nil {
            os_log("getRoutes task failed %{public}v", log: OSLog.net.log, type: .error, error.debugDescription)
            return [:]
        }

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
        
        let fieldSet = parseLineFields(lines, " ")
        var routes: [NetworkRoute] = fieldSet.map { fields in
            var route = NetworkRoute(ifName: "", ipAddress: "", ipGateway: "")
            for (i, val) in fields.enumerated() {
                switch i {
                case 0:
                    route.ipAddress = val
                case 1:
                    route.ipGateway = val
                case 2:
                    route.ifName = val
                default:
                    break
                }
            }
            return route
        }
        
        routes = routes.filter { route in
            !route.ipAddress.contains(":")
        }
        
        var result: [String: NetworkRoute] = [:]
        for route in routes {
            result[route.ipAddress] = route
        }
        return result
    }
   
    /// Add a given route to the routing table
    ///  NOTE: Will fail if not called as an administrator
    /// - Parameters:
    ///   - route: network route to add
    static func addRoute(_ route: NetworkRoute) {
        let task = Task(executable: "/sbin/route", arguments: ["-n", "add", route.ipAddress, route.ipGateway])
        _ = self.run(task)
    }

    /// Reset the route via DHCP for the supplied interface
    ///  NOTE: Will fail if not called as an administrator
    /// - Parameters:
    ///   - route: route with interface to reset
    static func resetRoute(_ route: NetworkRoute) {
        let task = Task(executable: "/usr/sbin/ipconfig", arguments: ["set", route.ifName, "DHCP"])
        _ = self.run(task)
    }

    /// Get the gateway used for the given ip segment
    /// - Parameter ipSeg: ip address segment to query
    /// Returns NetworkInterface with details
    /// route -n get 8.8.8.8
    static func getRoute(_ ipSeg: String) -> NetworkRoute? {
        let task = Task(executable: "/sbin/route", arguments: ["-n", "get", ipSeg])
        let (output, error) = self.run(task)
        if error != nil {
            os_log("getRoute task failed %{public}v", log: OSLog.net.log, type: .error, error.debugDescription)
            return nil
        }

        let lines = parseLines(output)
        let fieldSet = parseLineFields(lines, ":")
        var route = NetworkRoute(ifName: "", ipAddress: ipSeg, ipGateway: "")
        for fields in fieldSet {
            switch fields[0] {
            case "route to":
                route.ipAddress = fields[1]
            case "gateway":
                route.ipGateway = fields[1]
            case "interface":
                route.ifName = fields[1]
            default:
                break
            }
        }
        
        return route
    }

    /// Get the default system internet gateway route
    static func getDefaultRoute() -> NetworkRoute? {
        return getRoute("default")
    }

    /// Get the default LAN internet gateway route
    static func getDefaultLANRoute() -> NetworkRoute? {
        let routes = getLANRoutes()
        let lan = routes.filter { route in
            // assumption here is that on macos, all interfaces will have en? prefix
            route.ipAddress.contains(".") && route.ifName.hasPrefix("en")
        }
        guard var result = lan.first else {
            return nil
        }
        result.ipGateway = getRoute(result.ipAddress)?.ipGateway ?? ""
        return result
    }

    /// Get the LAN ip address set
    static func getLANRoutes() -> [NetworkRoute] {
        var result: [NetworkRoute] = []
        var ifAddrs: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifAddrs) == 0 else {
            os_log("getLANRoutes getifaddrs", log: OSLog.net.log, type: .error)
            return result
        }
        var pointer = ifAddrs
        while pointer != nil {
            defer { pointer = pointer?.pointee.ifa_next }
            guard let ifa = pointer?.pointee, ifa.ifa_addr.pointee.sa_family == UInt8(AF_INET),
                ifa.ifa_flags & UInt32(IFF_LOOPBACK) == 0, ifa.ifa_flags & UInt32(IFF_UP) != 0 else {
                continue
            }
            guard let ifaName = String(validatingUTF8: ifa.ifa_name) else {
                continue
            }
            var ipAddressRaw = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(ifa.ifa_addr, socklen_t(ifa.ifa_addr.pointee.sa_len), &ipAddressRaw, socklen_t(ipAddressRaw.count), nil, socklen_t(0), NI_NUMERICHOST)
            guard let ipAddress = String(validatingUTF8: ipAddressRaw) else {
                continue
            }
            result.append(NetworkRoute(ifName: ifaName, ipAddress: ipAddress, ipGateway: ""))
        }
        freeifaddrs(ifAddrs)
        return result
    }

    //
    // MARK: - Parsing
    //
    
    /// Parse a block of text into trimmed lines
    /// - Parameter text: text to parse
    /// Returns [String]
    static func parseLines(_ text: String) -> [String] {
        let lines = text.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\n")
        return lines.map { line in
            line.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /// Parse a a block of test into trimmed fields
    /// - Parameters:
    ///   - text: text to parse
    ///   - delimiter: delimiter between fields (empty delimiters will not be counted as fields eg. multiple spaces)
    /// Returns [String]
    static func parseFields(_ text: String, _ delimiter: Character) -> [String] {
        let fields = text.split(separator: delimiter)
        return fields.map { field in
            field.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { field in
            field.count > 0
        }
    }

    /// Parse an array of lines into an array of field arrays
    /// - Parameters:
    ///   - lines: lines to parse
    ///   - delimiter: delimiter between fields (empty delimiters will not be counted as fields eg. multiple spaces)
    /// Returns [[String]]
    static func parseLineFields(_ lines: [String], _ delimiter: Character) -> [[String]] {
        return lines.map { line in
            return parseFields(line, delimiter)
        }
    }

    //
    // MARK: - Tasks
    //
    
    /// Run a task parsing stdout and stderr
    /// - Parameter task: task definition to run
    /// Returns the stdout and stderr on completion
    static func run(_ task: Task) -> (String, Error?) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: task.executable)
        proc.arguments = task.arguments
    
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        proc.standardOutput = stdoutPipe
        proc.standardError = stderrPipe
        do {
            try proc.run()
        } catch let error {
            return ("", error)
        }
    
        let stdoutStr = String(decoding: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let stderrStr = String(decoding: stderrPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        
        var error: Error?
        if proc.terminationStatus != 0 {
            let errorText = stderrStr.trimmingCharacters(in: .whitespacesAndNewlines)
            error = NSError(domain: errorText, code: -1, userInfo: nil)
        }
        
        return (stdoutStr, error)
    }
}

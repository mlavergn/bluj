//
//  SCMac.swift
//  BluJ
//
//  Created by Lavergne, Marc on 3/26/20.
//  Copyright © 2020 Lavergne, Marc. All rights reserved.
//

import Foundation
import SystemConfiguration
import os

struct NetworkInterfaceSC: CustomDebugStringConvertible {
    var scni: SCNetworkInterface
    
    func ifName() -> String? {
        return SCNetworkInterfaceGetBSDName(self.scni) as String?
    }

    func ipAddress() -> String? {
        guard let ifName = self.ifName() else {
            return nil
        }
        return NetworkInfoSC.ipAddress(ifName)
    }
    
    func ifType() -> String? {
        // eg kSCNetworkInterfaceTypeEthernet
        SCNetworkInterfaceGetInterfaceType(self.scni) as String?
    }

    func ifSupportedTypes() -> [String]? {
        return SCNetworkInterfaceGetSupportedInterfaceTypes(self.scni) as NSArray? as? [String]
    }
    
    func isVPN() -> Bool {
        return self.ifName()?.hasPrefix("utun") ?? false
    }
   
    var debugDescription: String {
        return "\(ifName() ?? ""): \(ipAddress() ?? "") -> \(ifType() ?? "")"
    }
}

class NetworkInfoSC {
    
    /// Obtain the LAN address of the given interface
    /// - Parameter ifName: interface name
    static func ipAddress(_ ifName: String) -> String? {
        if let scInfo = SCDynamicStoreCopyValue(nil, "State:/Network/Interface/\(ifName)/IPv4" as CFString),
            let scAddresses = scInfo[kSCPropNetIPv4Addresses] as? [CFString],
            let scAddress = scAddresses.first {
                return scAddress as String
        }
        return nil
    }
    
    /// Force DHCP reset
    static func forceDHCP(ifName: String) {
        let ifcs = networkInterfaceMap()
        if let ni = ifcs[ifName] {
            SCNetworkInterfaceForceConfigurationRefresh(ni.scni)
        }
    }

    /// Set the DNS server
    /// - Parameter hosts: [String] of DNS hosts
    static func setDNS(_ hosts: [String] = ["8.8.8.8", "8.8.4.4"]) {
        let ifc = lanGateway()
        let dynamicStore = SCDynamicStoreCreate(nil, "setDNS" as NSString, nil, nil)
        let setting = ["ServerAddresses": hosts] as NSDictionary
        SCDynamicStoreSetValue(dynamicStore, "State:/Network/Service/\(ifc.serviceId)/DNS" as CFString, setting)
    }
    
    /// Obtain the default LAN gateway
    static func lanGateway() -> NetworkRoute {
        var route = NetworkRoute(ifName: "", ipAddress: "", ipGateway: "")
        let addresses: CFPropertyList? = SCDynamicStoreCopyValue(nil, "State:/Network/Global/IPv4" as CFString)
        addresses?.keyEnumerator().forEach { key in
            switch key as? NSString {
            case kSCDynamicStorePropNetPrimaryInterface:
                route.ifName = addresses?[kSCDynamicStorePropNetPrimaryInterface] as? String ?? ""
            case kSCPropNetIPv4Router:
                route.ipGateway = addresses?[kSCPropNetIPv4Router] as? String ?? ""
            case kSCDynamicStorePropNetPrimaryService:
                route.serviceId = addresses?[kSCDynamicStorePropNetPrimaryService] as? String ?? ""
            default:
                break
            }
        }
        if let ipAddress = ipAddress(route.ifName) {
            route.ipAddress = ipAddress
        }
        return route
    }

    /// Obtain the all the network interfaces
    static func vpnEnabled() -> Bool {
        self.networkInterfaces().filter { ni in
            ni.ifName()?.hasPrefix("utun") ?? false
        }.first != nil
    }

    /// Obtain the all the network interfaces
    static func networkInterfaces() -> [NetworkInterfaceSC] {
        let scnis = SCNetworkInterfaceCopyAll() as [AnyObject]
        return scnis.map { scni in
            return NetworkInterfaceSC(scni: scni as! SCNetworkInterface)
        }
    }
    
    /// Obtain the all the network interfaces mapped by interface name
    static func networkInterfaceMap() -> [String: NetworkInterfaceSC] {
        var result: [String: NetworkInterfaceSC] = [:]
        networkInterfaces().forEach { ni in
            if let ifName = ni.ifName() {
                result[ifName] = ni
            }
        }
        return result
    }
}

class DynamicStoreSC {
    var dynamicStore: SCDynamicStore?
    
    func registerNotifications() {
        guard let dynamicStore = SCDynamicStoreCreate(nil, "network_interface_detector" as NSString, { (store, changedKeys, info) in
            let keys: NSArray = changedKeys
            for key in keys {
                print(key)
            }
        }, nil) else {
            return
        }
        let keys = ["State:/Network/Interface"] as NSArray
        let patterns = [".*/IPv4"] as NSArray
        SCDynamicStoreSetNotificationKeys(dynamicStore, keys, patterns)
        self.dynamicStore = dynamicStore
    }
}

class NetworkSetSC {
    func names() -> [String] {
        guard let prefs = SCPreferencesCreate(nil, "SystemConfiguration" as NSString, nil),
            let netSets: NSArray = SCNetworkSetCopyAll(prefs) else {
            return []
        }
        return netSets.map { netSetRaw in
            let netSet: SCNetworkSet = netSetRaw as! SCNetworkSet
            return SCNetworkSetGetName(netSet) as String? ?? ""
        }.filter { name in
            return name.count != 0
        }
    }
}

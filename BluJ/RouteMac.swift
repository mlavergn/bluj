//
//  RouteMac.swift
//  BluJ
//
//  Created by Lavergne, Marc on 3/26/20.
//  Copyright © 2020 Lavergne, Marc. All rights reserved.
//

import Foundation

let Subnets: [String] = [
    "0.0.0.0",
    "128.0.0.0",
    "192.0.0.0",
    "224.0.0.0",
    "240.0.0.0",
    "248.0.0.0",
    "252.0.0.0",
    "254.0.0.0",
    "255.0.0.0",
    "255.128.0.0",
    "255.192.0.0",
    "255.224.0.0",
    "255.240.0.0",
    "255.248.0.0",
    "255.252.0.0",
    "255.254.0.0",
    "255.255.0.0",
    "255.255.192.0",
    "255.255.224.0",
    "255.255.128.0",
    "255.255.240.0",
    "255.255.248.0",
    "255.255.252.0",
    "255.255.254.0",
    "255.255.255.0",
    "255.255.255.128",
    "255.255.255.192",
    "255.255.255.224",
    "255.255.255.240",
    "255.255.255.248",
    "255.255.255.252",
    "255.255.255.254",
    "255.255.255.255",
]

struct NetworkRouteEntry: CustomDebugStringConvertible {
    let destination: String
    let netmask: String
    let gateway: String
    
    static func fromBSDRoute(route: BSDRoute) -> NetworkRouteEntry {
        return NetworkRouteEntry(destination: route.destination ?? "", netmask: route.netmask ?? "", gateway: route.gateway ?? "")
    }
    
    var debugDescription: String {
        return "\(destination): \(netmask) -> \(gateway)"
    }
}

class RouteMac {
    static func getRoutes() -> [NetworkRouteEntry] {
        guard let routes = BSDRoute.getRoutes() as? [BSDRoute] else {
            return []
        }
        return routes.map { route in
            return NetworkRouteEntry.fromBSDRoute(route: route)
        }
    }

    static func getDefaultRoute() -> NetworkRouteEntry? {
        self.getRoutes().filter { route in
            route.destination == "default"
        }.first
    }
    
    static func addRoute(destination: String, gateway: String, interface: String?) {
        BSDRoute.add(destination, ipGateway: gateway, ifName: interface)
    }
    
    static func delRoute(destination: String, gateway: String, interface: String?) {
        BSDRoute.add(destination, ipGateway: gateway, ifName: interface)
    }
}

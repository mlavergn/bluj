//
//  BluJUI.swift
//  BluJ
//
//  Created by Lavergne, Marc on 3/24/20.
//  Copyright © 2020 Lavergne, Marc. All rights reserved.
//

import Cocoa

class BluJUI {
    func menu() {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        
        let statusbar = NSStatusBar.system

        let statusItem = statusbar.statusItem(withLength:NSStatusItem.variableLength)
        statusItem.button?.title = "BluJ"
        statusItem.button?.toolTip = "BlueJeans VPN Re-Router"

        let bundle = Bundle(identifier: "com.marclavergne.BluJ")
  
        if let iconPath = bundle?.path(forResource: "BluJ-StatusBar", ofType: "pdf") {
            let image = NSImage(contentsOfFile: iconPath)
            statusItem.button?.image = image
        }

        let menu = NSMenu()

        let routeMenuItem = NSMenuItem()
        routeMenuItem.title = "Route BlueJeans Off VPN"
        routeMenuItem.target = self
        routeMenuItem.action = #selector(reset(_:))
        menu.addItem(routeMenuItem)

        let resetMenuItem = NSMenuItem()
        resetMenuItem.title = "Reset LAN Routes"
        resetMenuItem.target = self
        resetMenuItem.action = #selector(route(_:))
        menu.addItem(resetMenuItem)

        let quitMenuItem = NSMenuItem()
        quitMenuItem.title = "Quit"
        quitMenuItem.target = self
        quitMenuItem.action = #selector(quit(_:))
        menu.addItem(quitMenuItem)

        statusItem.menu = menu
    }

    @objc public func reset(_ sender:Any?) {
        print("BluJ Reset")
        let bluj = BluJ()
        guard let ifc = bluj.getDefaultLAN() else {
            return
        }
        bluj.resetRoute(ifc: ifc)
    }

    @objc public func route(_ sender:Any?) {
        print("BluJ Route")
        let bluj = BluJ()
        guard let ifc = bluj.getDefaultLAN() else {
            return
        }
        if !bluj.isBluejeansRouteLAN() {
             bluj.setBluejeansRoutes(ifc)
        }
    }

    @objc public func quit(_ sender:Any?) {
        print("BluJ Quit")
        NSApp.terminate(self)
    }

    func run() {
        menu()
        NSApp.run()
    }
}

//
//  Byway.swift
//  Byway
//
//  Created by Wesley Cope on 7/16/15.
//  Copyright © 2015 Wess Cope. All rights reserved.
//

/* USAGE:

Byway.addRoute("/boom") { (params:Dictionary) -> Bool in
    /* Do stuff with the route */

    return true
}

func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
    return Byway.runRoute(url)
}
*/

import Foundation

typealias RouteCallback = (params:Dictionary<String,String>)->(Bool)

class Route {
    static private var routes:[String:RouteCallback] = [String:RouteCallback]()
    
    static func convertQuery(url:NSURL) -> [String:String] {
        var dict = [String:String]()
        
        if let queries:[String] = url.query?.componentsSeparatedByString("&") {
            for query:String in queries {
                let components = query.componentsSeparatedByString("=")
                
                if components.count == 2 {
                    let key = components.first?.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
                    let val = components.last?.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
                    
                    dict[key!] = val
                }
            }
        }
        
        return dict

    }
    
    static func addRoute(route:String, callback:RouteCallback) {
        routes[route] = callback
    }
    
    static func runRoute(url:NSURL) -> Bool {
        let query = convertQuery(url)
        
        if let route = url.host {
            if let callback = routes[route] {
                callback(params: query)
                
                return true
            }
        }
        
        return false
    }
}

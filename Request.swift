//
//  Request.swift
//  Request
//
//  Created by Wesley Cope on 9/15/15.
//  Copyright © 2015 Wess Cope. All rights reserved.
//


/*
Example Usage:

let request = Request(baseUrl:"..")
    request.create { http in
        http.path       = "/users/profile/1"
        http.headers    = [...:...]
        http.params     = [...:...]
        http.post { success, response, error in
    }
}

// OR

request.get("/users/profile/1") { success, response, error in
}

*/

import Foundation

public typealias ResponseBlock = ((data:AnyObject?, response:NSURLResponse, error:NSError?) -> Void)

public enum HttpMethod : String {
    case GET    = "GET"
    case POST   = "POST"
    case PUT    = "PUT"
    case DELETE = "DELETE"
}

public class RequestModel {
    public var method:HttpMethod?
    public var path:String?
    public var params:[String:AnyObject]?
    public var completion:ResponseBlock?
    public var description:String {
        get {
            return "Method: \(method) \(path) - params: \(params)"
        }
    }

    private(set) public var auth:RequestAuthModel?
    
    public func enableAuth(username:String = "", password:String = "") {
        if username.length > 0 && password.length > 0 {
            auth = RequestAuthModel(username: username, password: password)
        }
    }
}

public struct RequestAuthModel {
    public var username:String?
    public var password:String?
}

public class Request {
    
    private lazy var config:NSURLSessionConfiguration   = NSURLSessionConfiguration.defaultSessionConfiguration()
    private lazy var session:NSURLSession               = NSURLSession(configuration: self.config)
    private var baseURL:String                          = ""
    
    public init(baseURL:String) {
        let toIndex     = baseURL.length - 1
        let subString   = baseURL[baseURL.length - 1]
        
        if subString == "/" {
            self.baseURL = baseURL.substringToIndex(baseURL.startIndex.advancedBy(toIndex))
            print("BSE: \(self.baseURL)")
        }
        else {
            self.baseURL = baseURL
        }
    }

    public func make(@noescape block:(http:RequestModel) -> Void) {
        let model       = RequestModel()
        model.method    = .GET

        block(http: model)        
        makeRequest(model)
    }
    
    public func get(path:String, params:[String:AnyObject]?, completion:ResponseBlock?) -> NSURLSessionTask? {
        let model           = RequestModel()
        model.method        = .GET
        model.params        = params
        model.completion    = completion
        
        makeRequest(model)
        
        return nil
    }
    
    public func post(path:String, params:[String:AnyObject]?, completion:ResponseBlock?) -> NSURLSessionTask? {
        let model           = RequestModel()
        model.method        = .POST
        model.params        = params
        model.completion    = completion
        
        makeRequest(model)
        
        return nil
    }
    
    private func makeRequest(model:RequestModel) -> NSURLSessionTask? {
        if var url = model.path {
            
            if url[0] != "/" {
                url = "/" + url
            }
            
            let request         = NSMutableURLRequest()
            request.HTTPMethod  = model.method!.rawValue

            if let query = model.params {
                let queryString = dictionaryToQueryString(query)

                if model.method == .POST {
                    if let data = queryString.dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: true) {
                        request.HTTPBody = data
                        request.setValue("\(data.length)", forHTTPHeaderField: "Content-length")
                    }
                }
                else {
                    url += "?\(queryString)"
                }
            }
            
            request.URL = NSURL(string: "\(baseURL)\(url)")
            
            if let auth = model.auth {
                let username    = auth.username == nil ? "" : auth.username!
                let password    = auth.password == nil ? "" : auth.password!
                let encodedAuth = "\(username):\(password)".dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: true)

                request.setValue("Basic \(encodedAuth)", forHTTPHeaderField: "Authorization")
            }
            
            let task = session.dataTaskWithRequest(request) { data, response, error in
                if let res = response as? NSHTTPURLResponse {
                    if error == nil {
                        if res.MIMEType == "text/html" {
                            if let responseData = data, let responseString = String(data: responseData, encoding: NSUTF8StringEncoding) {
                                if let block = model.completion {
                                    block(data:responseString, response:res, error:error)
                                }
                            }
                        }
                        else if res.MIMEType == "application/json" {
                            if let responseData = data {
                                do {
                                    let json = try NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers)
                                    
                                    if let block = model.completion {
                                        block(data:json, response:res, error:error)
                                    }
                                }
                                catch let jsonError as NSError {
                                    if let block = model.completion {
                                        block(data:nil, response:res, error:jsonError)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            task.resume()
            
            return task
        }
        else {
            fatalError("URL Path is required")
        }
        
        return nil
    }
    
    func dictionaryToQueryString(dict:[String:AnyObject]) -> String {
        var properties = [String]()
        
        for (key, val) in dict {
            let encodedKey = encoding(key)
            let encodedVal = encoding("\(val)")
            
            properties.append("\(encodedKey)=\(encodedVal)")
        }
        
        return properties.joinWithSeparator("&")
    }
    
    func encoding(str:String) -> String? {
        let chars = NSCharacterSet(charactersInString: " =\"#%/<>?@\\^`{}[]|&+").invertedSet
        let value = str.stringByAddingPercentEncodingWithAllowedCharacters(chars)
     
        return value
    }
}

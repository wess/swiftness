//
//  Alter.swift
//  Alter
//
//  Created by Wesley Cope on 7/16/15.
//  Copyright © 2015 Wess Cope. All rights reserved.
//


/* USAGE:


struct User {
    let name:String
    let email:String
    let nickname:String?
}

extension User:Alter {
    static func map(json: AnyObject) -> User {
        return try {
            name:       json >> "name",
            email:      json >> "email",
            nickname:   json >> "nickname"
        }
    }
}

*/

import Foundation

enum AlterError: ErrorType {
    case MissingKeyError(String, Any)
    case MismatchTypeError(String, Any)
    case InvalidJSONObject(AnyObject)
}

protocol Alter {
    static func map(node: AnyObject) throws -> Self
}

extension String: Alter {
    static func map(node: AnyObject) throws -> String {
        guard let result = node as? String else {
            throw AlterError.MismatchTypeError("String", node)
        }
        
        return result
    }
}


extension Int: Alter {
    static func map(node: AnyObject) throws -> Int {
        guard let result = node as? Int else {
            throw AlterError.MismatchTypeError("Int", node)
        }
        
        return result
    }
}

extension Double: Alter {
    static func map(node: AnyObject) throws -> Double {
        guard let result = node as? Double else {
            throw AlterError.MismatchTypeError("Double", node)
        }
        
        return result
    }
}

infix operator >> {
associativity left precedence 150
}

infix operator >>? {
    associativity left precedence 150
}

func >> <T:Alter>(left: AnyObject, right: String) throws -> T {
    guard let dict = left as? [String: AnyObject] else {
        throw AlterError.InvalidJSONObject(left)
    }
    
    guard let object = dict[right] else {
        throw AlterError.MissingKeyError(right, dict)
    }
    
    return try T.map(object)
}

func >> (left: AnyObject, right: String) throws -> [String: AnyObject] {
    guard let dict = left as? [String: AnyObject] else {
        throw AlterError.InvalidJSONObject(left)
    }
    
    guard let object = dict[right] else {
        throw AlterError.MissingKeyError(right, dict)
    }
    
    guard let result = object as? [String: AnyObject] else {
        throw AlterError.MismatchTypeError("Valid JSON Object", object)
    }
    
    return result
}

func >> <T:Alter>(left: AnyObject, right: String) -> T? {
    do {
        let result:T = try left >> right
        
        return result
    }
    catch {
        return nil
    }
}

func >>? <T:Alter>(left: AnyObject, right: String) throws -> [T] {
    guard let dict = left as? [String: AnyObject] else {
        throw AlterError.InvalidJSONObject(left)
    }
    
    guard let list = dict[right] as? [AnyObject] else {
        throw AlterError.MismatchTypeError("Array", left)
    }
    
    var result = [T]()
    
    for node in list {
        do {
            try result.append(T.map(node))
        }
        catch let AlterError.MismatchTypeError(key, val) {
            print("Optional: Type mismatch - \(key): \(val)")
        }
        catch let AlterError.InvalidJSONObject(obj) {
            print("Optional: Invalid object - \(obj)")
        }
        catch let AlterError.MissingKeyError(key, val) {
            print("Optional: Missing key - \(key): \(val)")
        }
    }

    return result
}




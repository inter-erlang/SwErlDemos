//
//  TriangularDistributionServer.swift
//  JunkyPlay
//
//  Created by yenrab on 3/19/24.
//

import Foundation
import SwErl

enum Triangular{
    case next
}

enum TriangularDistributionServer:GenServerBehavior{
    
    @discardableResult static func startLink(named:String, initialState:Any? = nil)->String?{
        do{
            return try GenServer.startLink(named, TriangularDistributionServer.self, initialState)
        }
        catch{
            //no handling
        }
        return nil
    }
    static func next(from:String)->Double?{
        do{
            let (passed, result) = try GenServer.call(from,Triangular.next)
            guard let result = result as? Double, passed == SwErlPassed.ok else{
                return nil
            }
            return result
        }
        catch{}
        return nil
    }
    static func initializeData(_ data: Any?) -> Any? {
        guard ((data as? (Double,Double,Double)) != nil) else{
            return nil
        }
        return data
    }
    
    
    static func handleCall(request: Any, data: Any) -> (Any, Any) {
        guard let command = request as? Triangular, let (min,max,mode) = data as? (Double,Double,Double), command == Triangular.next else{
            return (SwErlPassed.fail,data)
        }
        // Get next normally distributed random number
        let triangularRandom = triangularDistribution(min: min, max: max, mode: mode)
        
        return(triangularRandom,data)
    }
    
    //unused functions here
    static func terminateCleanup(reason: String, data: Any?) {
        return
    }
    
    static func handleCast(request: Any, data: Any?) -> Any? {
        return data
    }
    
}

func triangularDistribution(min a: Double, max b: Double, mode c: Double) -> Double {
    let u = Double.random(in: 0..<1)
    let f = (c - a) / (b - a)

    if u < f {
        return a + sqrt(u * (b - a) * (c - a))
    } else {
        return b - sqrt((1 - u) * (b - a) * (b - c))
    }
}


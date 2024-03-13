//
//  LogNormalServer.swift
//  JunkyPlay
//
//  Created by yenrab on 2/28/24.
//

import Foundation
import SwErl
import GameplayKit

enum LogNormal{
    case next
}

enum LogNormalServer:GenServerBehavior{
    
    @discardableResult static func startLink(named:String, initialState:Any? = nil)->String?{
        do{
            return try GenServer.startLink(named, LogNormalServer.self, initialState)
        }
        catch{
            //no handling
        }
        return nil
    }
    static func next(from:String)->Float?{
        do{
            let (passed, result) = try GenServer.call(from,LogNormal.next)
            guard let result = result as? Float, passed == SwErlPassed.ok else{
                return nil
            }
            return result
        }
        catch{}
        return nil
    }
    static func initializeData(_ data: Any?) -> Any? {
        guard let (mean,standardDeviation) = data as? (Float,Float) else{
            return nil
        }
        return GKGaussianDistribution(randomSource: GKRandomSource(), mean: mean, deviation: standardDeviation)
    }
    
    
    static func handleCall(request: Any, data: Any) -> (Any, Any) {
        guard let command = request as? LogNormal, let distribution = data as? GKGaussianDistribution, command == LogNormal.next else{
            return (SwErlPassed.fail,data)
        }
        // Get next normally distributed random number
        let normalRandom = distribution.nextUniform()
        
        // Transform the normally distributed number to log-normal
        let logNormalRandom =  exp(normalRandom)
        return(logNormalRandom,distribution)
    }
    
    //unused functions here
    static func terminateCleanup(reason: String, data: Any?) {
        return
    }
    
    static func handleCast(request: Any, data: Any?) -> Any? {
        return data
    }
    
}

//another possibility
func triangularDistribution(min a: Double, max b: Double, mode c: Double) -> Double {
    let u = Double.random(in: 0..<1)
    let f = (c - a) / (b - a)

    if u < f {
        return a + sqrt(u * (b - a) * (c - a))
    } else {
        return b - sqrt((1 - u) * (b - a) * (b - c))
    }
}


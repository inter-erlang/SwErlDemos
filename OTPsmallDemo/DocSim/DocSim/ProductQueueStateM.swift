//
//  PreBoxingQueueStatem.swift
//  DocSim
//
//  Created by yenrab on 2/29/24.
//

import Foundation
import SwErl

enum ProductQueueStateM:GenStatemBehavior{
    case popProduct
    case pushProduct
    
    //
    //API functions
    //
    static func startLink(initialBoxCount capacityUsed:UInt = 0, queueCapacity:UInt)throws{
        try GenStateM.startLink(name: "productQueue", statem: ProductQueueStateM.self, initialData: (queueCapacity,capacityUsed))//there will only be one product queue in the simulation so we can hardcode the name
    }
    
    static func pickProduct()->SwErlPassed{
        let (success,_) = GenStateM.call(name: "productQueue", message: ProductQueueStateM.popProduct)
        return success
    }
    
    static func putProduct(){
        GenStateM.cast(name: "productQueue", message: ProductQueueStateM.pushProduct)
    }
    
    //
    //Internal Functions
    //
    
    static func initialize(initialData: Any) -> SwErl.SwErlState {
        initialData//this is the (capacity,used) tuple.
    }
    
    
    static func handleCast(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> SwErl.SwErlState {
        //the message sent, .pushProduct, is ignored since there is currently no other message sent to handleCast.
        guard let (queueCapacity,productCount) = current_state as? (UInt,UInt), productCount < queueCapacity else{
            return current_state
        }
        return (queueCapacity,productCount + 1)
    }
    
    static func handleCall(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> (SwErl.SwErlResponse, SwErl.SwErlState) {
        //the message sent, .popProduct, is ignored since there is currently no other message sent to handleCast.
        guard let (queueCapacity,productCount) = current_state as? (UInt,UInt), productCount > 0 else{
            return ((SwErlPassed.fail,nil as Any?),current_state)
        }
        return ((SwErlPassed.ok,nil as Any?),(queueCapacity,productCount - 1))
    }
    
    
    //unused functions
    static func notify(message: SwErl.SwErlMessage, state: SwErl.SwErlState) {
        //unused
    }
    
    
    static func unlinked(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) {
        //unused
    }
    
    
}

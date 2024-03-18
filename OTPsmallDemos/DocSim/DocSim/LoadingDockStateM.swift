//
//  LoadingDockStateM.swift
//  DocSim
//
//  Created by yenrab on 2/29/24.
//

import Foundation
import SwErl

enum LoadingDockStateM:GenStatemBehavior{
    case getBox
    case addBox
    
    //
    //API functions
    //
    static func startLink(initialBoxCount:UInt)throws{
            try GenStateM.startLink(name: "loadingDock", statem: LoadingDockStateM.self, initialData: initialBoxCount)//there will only be one loading dock in the simulation so we can hardcode the name
    }
    
    static func packageSelected()->SwErlPassed{
        let (success,_) = GenStateM.call(name: "loadingDock", message: LoadingDockStateM.getBox)
        return success
    }
    
    static func putPackage(){
        GenStateM.cast(name: "loadingDock", message: LoadingDockStateM.addBox)
    }
    
    //
    //internally used functions
    //
    static func initialize(initialData: Any) -> SwErl.SwErlState {
        initialData//this is how many boxes are already on the loading dock
    }
    static func handleCall(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> (SwErl.SwErlResponse, SwErl.SwErlState) {
        guard let boxCount = current_state as? UInt, boxCount > 0 else{
            return ((SwErlPassed.fail,nil as Any?),current_state)
        }
        return ((SwErlPassed.ok,nil as Any?),boxCount - 1)
    }
    
    static func handleCast(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> SwErl.SwErlState {
        guard let boxCount = current_state as? UInt, boxCount >= 0 else{
            return 0//reset the box count
        }
        return boxCount + 1
    }
    
    
    //unused functions
    static func notify(message: SwErl.SwErlMessage, state: SwErl.SwErlState) {
        //do nothing
    }
    
    static func unlinked(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) {
        //do nothing
    }
    
    
    
}

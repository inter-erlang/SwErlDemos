//
//  PersonStateM.swift
//  DocSim
//
//  Created by yenrab on 2/29/24.
//

import Foundation
import SwErl

enum PersonStateM:GenStatemBehavior{
    enum Request{
        case getStats
    }
    case boxing//boxing product
    case loading//loading the truck
    case continuing//continuing to load the truck
    case idle//waiting at the boxing table
    case delivering//walking both ways from the table to the loading dock and stacking the box on the dock
    case returning//returning to the boxing table after loading the truck
    
    
    static func startLink(named:String, initialState:PersonStateM, walkTime:Double,boxingTime:Double,loadingTime:Double)throws{
        let assembledState = (named,initialState,0, (0.0,0.0,0.0),(walkTime,boxingTime,loadingTime))
        try GenStateM.startLink(name: named, statem: PersonStateM.self, initialData: assembledState)
    }
    
    static func changeState(for person:String,to nextState:PersonStateM){
        GenStateM.cast(name: person, message: nextState)
    }
    
    static func getStats(for person:String) -> (Double,Double,Double)?{
        guard let (passed,percentages) = GenStateM.call(name: person, message: PersonStateM.Request.getStats) as? (SwErlPassed,(Double,Double,Double)), passed == SwErlPassed.ok else{//message ignored anyway.
            return nil
        }
        return percentages
    }
    
    
    
    
    static func initialize(initialData: Any) -> SwErl.SwErlState {
        initialData
    }
    static func handleCall(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> (SwErl.SwErlResponse, SwErl.SwErlState) {
        guard let (_,_,_,(idleTime,boxingTime,loadingTime),_) = current_state as? (String,PersonStateM,Int,(Double,Double,Double),(Double,Double,Double)) else{
            return ((SwErlPassed.fail,"bad state"),current_state)
        }
        guard let _ = message as? PersonStateM.Request else{//there is only one message type currently being sent, getting the stats
            return ((SwErlPassed.fail,"bad request \(message)"),current_state)
        }
        //calculate percentage in time stats
        let total = idleTime + boxingTime + loadingTime
        var stats = (0.0,0.0,0.0)
        if total > 0.0{
            stats = (100*idleTime/total,100*boxingTime/total,100*loadingTime/total)
        }
        return ((SwErlPassed.ok,stats),current_state)
    }
    
    static func handleCast(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> SwErl.SwErlState {
        
        guard let (name,currentWorkState,idleTracker, (idleTime,boxingTime,loadingTime),(stdWalkingTime,stdboxingTime,stdLoadingTime)) = current_state as? (String,PersonStateM,Int,(Double,Double,Double),(Double,Double,Double)) else{
            return current_state
        }
        guard let stateToChangeTo = message as? PersonStateM else{
            return current_state
        }
        
        guard let lnRand = TriangularDistributionServer.next(from: "triaserver") else{
            return current_state
        }
        let randAsDouble = Double(lnRand)
        print("state change request: \((currentWorkState,stateToChangeTo)) for \(name)")
        switch (currentWorkState,stateToChangeTo){
        case (.boxing, .loading), (.idle, .loading):
            //calculate walking time
            let aWalkingTime = stdWalkingTime * randAsDouble
            spawnNextStateChange(at: aWalkingTime, for: name, state: .continuing)
            var anIdleTime = 0.0
            if(idleTracker > 0){
                anIdleTime = Double(Int(Date().timeIntervalSince1970) - idleTracker)
            }
            //update idleTime, reset idleTracker, update
            //currently treating walking time as idle time
            return (name,PersonStateM.loading,0, (idleTime + anIdleTime + aWalkingTime,boxingTime,loadingTime),(stdWalkingTime,stdboxingTime,stdLoadingTime))
        case (.loading,.continuing),(.continuing,.continuing),(.delivering,.loading)://if you are .loading and get a .loading request.
            var aLoadingTime:Double = 0.0
            if SwErlPassed.ok == LoadingDockStateM.packageSelected(){//found a box
                TruckStateM.putBox()
                aLoadingTime = randAsDouble*stdLoadingTime
                spawnNextStateChange(at: aLoadingTime, for: name, state: .continuing)
            }
            else{//ran out of boxes
                
                spawnNextStateChange(at: 0.1, for: name, state: .returning)
            }
            //currently treating walking time as idle time
            return (name,PersonStateM.continuing,idleTracker, (idleTime,boxingTime,loadingTime + aLoadingTime),(stdWalkingTime,stdboxingTime,stdLoadingTime))
            
        case (.boxing, .idle)://ran out of work
            //record current time for calculating time in idle. send as part of the state.
            let startTrackerTime = Int(Date().timeIntervalSince1970)
            
            return (name,currentWorkState,startTrackerTime, (idleTime,boxingTime,loadingTime),(stdWalkingTime,stdboxingTime,stdLoadingTime))
        case (.idle,.boxing), (.delivering,.boxing), (.returning, .boxing):
            guard ProductQueueStateM.pickProduct() == .ok else{
                //if no box, stay .idle
                return current_state
            }
            var anIdleTime:Int = 0
            if idleTracker > 0{
                anIdleTime = Int(Date().timeIntervalSince1970) - idleTracker
            }
            //since there is a box, go into boxing state and delay.
            let aBoxingTime = randAsDouble * stdboxingTime
            spawnNextStateChange(at: aBoxingTime, for: name, state: .delivering)
            //update the state and change to .boxing and idleTracker to 0
            return (name,PersonStateM.boxing,0, (idleTime + Double(anIdleTime),boxingTime +  aBoxingTime,loadingTime),(stdWalkingTime,stdboxingTime,stdLoadingTime))
        case (.boxing, .delivering):
            //calculate delivery walking and stacking time
            //calculate the return walking time
            let roundTripTime = randAsDouble * stdWalkingTime * 2.0
            //delay the next state change the sum of the walking times
            //change state to boxing.
            spawnNextStateChange(at: roundTripTime, for: name, state: .boxing)
            //update the state with the delivery time sum
            //currently treating this walking time as idle time
            return (name,PersonStateM.delivering,0, (idleTime + roundTripTime,boxingTime,loadingTime),(stdWalkingTime,stdboxingTime,stdLoadingTime))
            
        case (.continuing,.returning),(.loading,.returning):
            //calculate a walking time.
            let aWalkingTime = randAsDouble * stdWalkingTime
            spawnNextStateChange(at: aWalkingTime, for: name, state: .boxing)
            return (name,PersonStateM.returning,idleTracker, (idleTime + aWalkingTime,boxingTime,loadingTime),(stdWalkingTime,stdboxingTime,stdLoadingTime))
        default://unused state change request type
            print("invalid state change request: \((currentWorkState,stateToChangeTo))")
            return current_state
        }
    }
    

    //these are unused for this example.
    static func unlinked(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) {
        //do nothing
    }
    
    static func notify(message: SwErl.SwErlMessage, state: SwErl.SwErlState) {
        //do nothing
    }
    
    
    
    
    //
    //Helper functions
    //
    fileprivate static func spawnNextStateChange(at aTime: Double, for name: String, state:PersonStateM) {
        DispatchQueue.main.asyncAfter(deadline: .now() + aTime) {
            // This block will be executed after a delay of aTime seconds
            PersonStateM.changeState(for: name, to: state)
        }
    }
}






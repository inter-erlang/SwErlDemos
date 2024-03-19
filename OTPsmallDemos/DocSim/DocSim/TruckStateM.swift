//
//  TruckStateM.swift
//  DocSim
//
//  Created by yenrab on 3/1/24.
//

import Foundation
import SwErl

enum TruckStateM:GenStatemBehavior{
    case put
    case depart
    case arrive
    case stats
    
    enum state{
        case available
        case notAvailable
    }
    
    //
    //API functions
    //
    static func startLink(for name:String = "truck",boxCapacity:UInt, arrivalInterval:Double, loadingTimeInterval: Double)throws{
        
        let pid = try GenStateM.startLink(name: name, statem: TruckStateM.self, initialData: (boxCapacity,arrivalInterval,loadingTimeInterval))//there will only be one truck simulating many in the simulation so we can hardcode the name
    }
    
    
    static func putBox(on named:String = "truck"){
        GenStateM.cast(name:named, message: TruckStateM.put)
    }
    
    static func leaveDock(named:String = "truck", statsOnly:Bool = false){
        if statsOnly{
            GenStateM.cast(name:named, message: TruckStateM.stats)
        }
        else{
            GenStateM.cast(name:named, message: TruckStateM.depart)
        }
    }
    
    static func getAverageLoadedStat(for named:String = "truck")->Double?{
        guard let (success,stat) = GenStateM.call(name: named, message: TruckStateM.stats) as? (SwErlPassed,Double), success == SwErlPassed.ok else{
            return nil//failure indicator
        }
        return stat
    }
    
    
    //
    //Internal Functions
    //
    static func initialize(initialData: Any) -> SwErl.SwErlState {
        (initialData,UInt(0),[UInt]())//initial data is the truckCapacity. The second element is the used capacity and arrival interval tuple, the third is the tracker for the filled-percentage added each time 'a truck' leaves the loading dock.
    }
    static func handleCast(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> SwErl.SwErlState {
        guard let ((capacity,stdArrivalTime,stdLoadingTime),filled,filledTracker) = current_state as? ((UInt,Double,Double),UInt,[UInt]), let request = message as? TruckStateM else{
            return current_state
        }
        switch request{
        case .put:
            if filled + 1 >= capacity {
                print("truck leaving full")
                TruckStateM.leaveDock()
            }
            return ((capacity,stdArrivalTime,stdLoadingTime),filled + 1,filledTracker)
        case .depart:
            print("\n\n\n!!!!!!!!!!!!!!!!\ntruck departing\n!!!!!!!!!!!!!!!!!!!!\n\n\n")
            guard let lnRand = TriangularDistributionServer.next(from: "triaserver") else{
                return current_state
            }
            let nextArrivalTime = Double(lnRand) * stdArrivalTime
            
            guard let leaveLnRand = TriangularDistributionServer.next(from: "triaserver") else{
                return current_state
            }
            let nextLeaveTime = nextArrivalTime + Double(leaveLnRand) * stdLoadingTime
            print("notifying truck leave manager")
            EventManager.notify(name: "truckLeaveManager", message: (TruckStateM.depart,nextArrivalTime,nextLeaveTime))
            
            var localTracker = filledTracker
            if filled != 0{
                print("truck \(100.0*Double(filled)/Double(capacity))% full")
                localTracker.append(filled)
            }
            return ((capacity,stdArrivalTime,stdLoadingTime),UInt(0),localTracker)
            
        case .stats:
            var localTracker = filledTracker
            if filled != 0{
                print("truck \(100.0*Double(filled)/Double(capacity))% full")
                localTracker.append(filled)
            }
            return ((capacity,stdArrivalTime,stdLoadingTime),UInt(0),localTracker)
            
        default:
            return current_state//invalid command
        }
        
    }
    static func handleCall(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> (SwErl.SwErlResponse, SwErl.SwErlState) {
        //message ignored since there is only one type of message, .stats, being sent.
        guard let ((capacity,_,_),_,filledTracker) = current_state as? ((UInt,Double,Double),UInt,[UInt]) else{
            return ((SwErlPassed.fail,nil as UInt?),current_state)
        }
        var averagePercentFilled = 0.0
        if filledTracker.count > 0{
            averagePercentFilled = 100.0 * Double(filledTracker.reduce(0, +))/Double(filledTracker.count)/Double(capacity)
        }
        return ((SwErlPassed.ok,averagePercentFilled),current_state)
    }
    
    
    //unused
    static func notify(message: SwErl.SwErlMessage, state: SwErl.SwErlState) {
        //unused
    }
    
    static func unlinked(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) {
        //unused
    }
    
    //
    //Helper functions
    //
    fileprivate static func spawnFirstTruck(at aTime: Double, for name: String, state:PersonStateM) {
        DispatchQueue.main.asyncAfter(deadline: .now() + aTime) {
            // This block will be executed after a delay of aTime seconds
            
        }
    }
}

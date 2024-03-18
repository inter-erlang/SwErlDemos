//
//  SimEventManager.swift
//  DocSim
//
//  Created by yenrab on 3/1/24.
//

import Foundation
import SwErl



func startManagerLinks(){
    //
    //setup the manager's handlers
    //
    let truckLeaveHandlers = [{(PID:Pid,message:SwErlMessage) in//have this one notify the workers the truck has left
        print("sending people back")
        PersonStateM.changeState(for: "bob", to: PersonStateM.returning)
        PersonStateM.changeState(for: "camila", to: PersonStateM.returning)
        
        return},{(PID:Pid,message:SwErlMessage) in//have this one bring the truck back into the loading dock...eventually
            guard let (_,arrivalTime,_) = message as? (TruckStateM,Double,Double) else{
                print("didn't get correct message")
                return
            }
            print("next truck arrives in \(arrivalTime)")
            //use delay the time of the next truck arrival.
            DispatchQueue.main.asyncAfter(deadline: .now() + arrivalTime) {
                print("\n\n\n!!!!!!!!!!!!!!\ntruck arrived\n!!!!!!!!!!!!!!!!!!\n\n\n")
                // This block will be executed after a delay of aTime seconds
                PersonStateM.changeState(for: "bob", to: PersonStateM.loading)
                PersonStateM.changeState(for: "camila", to: PersonStateM.loading)
            }
        }]
    
    //
    //start the manager
    //
    do{
        try EventManager.link(name: "truckLeaveManager", intialHandlers: truckLeaveHandlers)
    }
    catch{
        //ignore
    }
}



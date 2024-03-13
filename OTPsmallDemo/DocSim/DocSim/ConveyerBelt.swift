//
//  ConveyerBelt.swift
//  DocSim
//
//  Created by yenrab on 3/1/24.
//

import Foundation

func streamProduct(arrivalInterval theInterval:UInt){//seconds
    
    guard let lnRand = LogNormalServer.next(from: "lnserver") else{
        print("failed to gen random")
        return
    }
    //use a timer to delay the time.
    Timer.scheduledTimer(withTimeInterval: TimeInterval(Float(theInterval) * lnRand), repeats: false) { _ in
        ProductQueueStateM.putProduct()
        streamProduct(arrivalInterval: theInterval)
        return//this is returning from the timer, not the function
    }
}

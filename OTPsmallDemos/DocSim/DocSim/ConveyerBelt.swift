//
//  ConveyerBelt.swift
//  DocSim
//
//  Created by yenrab on 3/1/24.
//

import Foundation

func streamProduct(arrivalInterval theInterval:UInt){//seconds
    
    guard let triaRand = TriangularDistributionServer.next(from: "triaserver") else{
        print("failed to gen random")
        return
    }
    //use a timer to delay the time.
    Timer.scheduledTimer(withTimeInterval: TimeInterval(Double(theInterval) * triaRand), repeats: false) { _ in
        ProductQueueStateM.putProduct()
        streamProduct(arrivalInterval: theInterval)
        return//this is returning from the timer, not the function
    }
}

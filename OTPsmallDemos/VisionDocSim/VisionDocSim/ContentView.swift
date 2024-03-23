//
//  ContentView.swift
//  VisionDocSim
//
//  Created by Barney, Lee on 3/23/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import Charts
import SwErl

struct Statistic: Identifiable {
    var type: String
    var percentage: Double
    var id = UUID()
}
struct ContentView: View {
    @State var bobStats = [
        Statistic(type: "w", percentage: 0.0),
        Statistic(type: "b", percentage: 0.0),
        Statistic(type: "l", percentage: 0.0)]
    @State var camilaStats = [
        Statistic(type: "w", percentage: 0.0),
        Statistic(type: "b", percentage: 0.0),
        Statistic(type: "l", percentage: 0.0)]
    
    @State var truckLeavePercentFull:UInt = 0
    let colorMap:[String:Color] = ["w":.green,"b":.blue,"l":.orange]
    var body: some View {
        VStack {
            HStack{
                VStack{
                    Text("camila")
                    Chart(camilaStats) { aStatistic in
                        SectorMark(
                            angle: .value(
                                Text(verbatim: aStatistic.type),
                                aStatistic.percentage
                            )
                        ).foregroundStyle(colorMap[aStatistic.type] ?? .gray)
                    }.chartLegend(.hidden)
                }
                VStack{
                    Text("bob")
                    Chart(bobStats) { aStatistic in
                        SectorMark(
                            angle: .value(
                                Text(verbatim: aStatistic.type),
                                aStatistic.percentage
                            )
                        ).foregroundStyle(colorMap[aStatistic.type] ?? .gray)
                    }.chartLegend(.hidden)
                }
                VStack{
                    Text("truck")
                    Spacer()
                    Text("\(truckLeavePercentFull)").foregroundStyle(Color.yellow)
                    Spacer()
                }
            }//end of HStack
            HStack{
                Spacer()
                Text("box").foregroundStyle(colorMap["b"] ?? Color.gray)
                Text("walk").foregroundStyle(colorMap["w"] ?? Color.gray)
                Text("load").foregroundStyle(colorMap["l"] ?? Color.gray)
                Spacer()
                Text("%full").foregroundStyle(Color.yellow)
                
            }
            Spacer()
            HStack{
                Button("start"){
                    startSim()
                }
                
            }
        }
        .padding()
    }
    func startSim() {
        do{
            try spawnasysl{selfPid,message in
            }
            try PersonStateM.startLink(named: "bob", initialState: .loading, walkTime: 1, boxingTime: 1, loadingTime: 4)
            try PersonStateM.startLink(named: "camila", initialState: .loading, walkTime: 1, boxingTime: 1, loadingTime: 4)
            try TruckStateM.startLink(boxCapacity: 30, arrivalInterval: 30.0, loadingTimeInterval: 15.0)//seconds
            let min:Double = 0.1
            let max:Double = 1.0
            let mode:Double = 0.6
            TriangularDistributionServer.startLink(named: "triaserver", initialState: (min,max,mode))
            try ProductQueueStateM.startLink(initialBoxCount: 45, queueCapacity: 50)
            try LoadingDockStateM.startLink(initialBoxCount: 35)
            
            startManagerLinks()
            
            streamProduct(arrivalInterval: 1)
            startTruckStream()
            Timer.scheduledTimer(withTimeInterval: 2, repeats: true){_ in
                //get all of the stats
                guard
                    var (bobIdle,bobBoxing,bobLoading) = PersonStateM.getStats(for: "bob") else{
                    print("couldn't get bob stats")
                    return
                }
                
                guard var (camilaIdle,camilaBoxing,camilaLoading) = PersonStateM.getStats(for: "camila") else{
                    print("couldn't get camila stats")
                    return
                }
                guard let truckLoadPercentage = TruckStateM.getAverageLoadedStat() else{
                    print("couldn't get truck stats\n\n\n")
                    return
                }
                
                //update the the chart's data
                if bobIdle + bobBoxing + bobLoading > 100.0{
                    bobIdle = floor(bobIdle)
                    bobBoxing = floor(bobBoxing)
                    bobLoading = floor(bobLoading) + 1.0
                }
                if camilaIdle + camilaBoxing + camilaLoading > 100.0{
                    camilaIdle = floor(camilaIdle)
                    camilaBoxing = floor(camilaBoxing)
                    camilaLoading = floor(camilaLoading) + 1.0
                }
                bobStats[0].percentage = bobIdle
                bobStats[1].percentage = bobBoxing
                bobStats[2].percentage = bobLoading
                
                camilaStats[0].percentage = camilaIdle
                camilaStats[1].percentage = camilaBoxing
                camilaStats[2].percentage = camilaLoading
                truckLeavePercentFull = UInt(truckLoadPercentage)
            }
        }
        catch{
            print("couldn't get stats \(error)")
        }//ignore
    }
}

//
//Helper functions
//
func startTruckStream() {
    TruckStateM.leaveDock()
}

#Preview(windowStyle: .automatic) {
    ContentView()
}

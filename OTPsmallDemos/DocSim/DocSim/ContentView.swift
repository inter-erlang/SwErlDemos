//
//  ContentView.swift
//  DocSim
//
//  Created by yenrab on 2/29/24.
//

import SwiftUI
import Charts
import SwErl

struct Statistic: Identifiable {
    var type: String
    var person: String
    var percentage: Double
    var id = UUID()
}

struct ContentView: View {
    @State var displayData: [Statistic] = [
        .init(type: "walking", person: "bob", percentage: 0.0),
        .init(type: "boxing", person: "bob", percentage: 0.0),
        .init(type: "loading", person: "bob", percentage: 0.0),
        .init(type: "walking", person: "camile", percentage: 0.0),
        .init(type: "boxing", person: "camile", percentage: 0.0),
        .init(type: "loading", person: "camile", percentage: 0.0),
        .init(type: "%Full", person: "truck % full", percentage: 0.0)
    ]
    var body: some View {
        VStack {
            HStack{
                Image("Header")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 100.0)
                    .clipped()
            }
            Chart {
                ForEach(displayData) { stat in
                        BarMark(
                            x: .value("person", stat.person),
                            y: .value("percentage", stat.percentage)
                        )
                        .foregroundStyle(by: .value("type", stat.type))
                    }
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
            let mean:Float = 0.0
            let sigma:Float = 0.4
            LogNormalServer.startLink(named: "lnserver", initialState: (mean,sigma))
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
                displayData[0].percentage = bobIdle
                displayData[1].percentage = bobBoxing
                displayData[2].percentage = bobLoading
                displayData[3].percentage = camilaIdle
                displayData[4].percentage = camilaBoxing
                displayData[5].percentage = camilaLoading
                displayData[6].percentage = truckLoadPercentage
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

#Preview {
    ContentView()
}

//
//  ContentView.swift
//  SwErlDemo
//
//  Created by yenrab on 2/28/24.
//

import SwiftUI
import SwErl

struct ContentView: View {
    @State private var message = "0"
    var body: some View {
        VStack {
            Image("SwErl")
            Spacer()
            Text(message).accentColor(.accentColor)
            Spacer()
            Button("Go Go SwiftUI!"){
                "go" ! ()//empty tuple
            }
        }.onAppear {
            spawnAll()
        }
        .padding()
    }
    
    
    
    func spawnAll(){
        do{
            try spawnasysf(name:"go",initialState: 0){Pid,_,state in
                guard let state = state as? Int else{
                    
                    return
                }
                let count = state + 1
                "show" ! count
                return count
            }
            try spawnasysl(queueToUse:.main, name:"show"){Pid,count in
                message = "\(count)"
            }
        }
        catch{
            message = error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
}

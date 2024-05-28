//
//  ContentView.swift
//  iOSBLEBrowser
//
//  Created by Nick Lambourne on 10/20/22.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View, ParticleBLEScanningObservableDelegate {
    func stateUpdated() {
        
    }

    @StateObject var particleBLEScanningObservable = ParticleBLEScanningObservable()
    
    let serviceUUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
    
    var body: some View {
        NavigationView {
            VStack() {
                Text("Discovered Peripherals")
                List(particleBLEScanningObservable.discoveredPeripherals, id: \.name) { device in
                    HStack() {
                        Text(device.name).padding()
                        Spacer()
                        Text(device.uuid).padding()

                        //if our device is in the list and its disconnected, show a red circle
                        if particleBLEScanningObservable.discoveredPeripherals.contains(where: { $0.uuid == device.uuid && $0.state == .disconnected }) {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 20, height: 20)
                        }
                        //if our device is in the list and its connecting, show an orange circle
                        else if particleBLEScanningObservable.discoveredPeripherals.contains(where: { $0.uuid == device.uuid && $0.state == .connecting }) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 20, height: 20)
                        }
                        else if particleBLEScanningObservable.discoveredPeripherals.contains(where: { $0.uuid == device.uuid && $0.state == .connectingDiscoveringCharacterstics }) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 20, height: 20)
                        }
                        //if our device is in the list and its connected, show a green circle
                        else if particleBLEScanningObservable.discoveredPeripherals.contains(where: { $0.uuid == device.uuid && $0.state == .connected }) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 20, height: 20)
                        }
                    }
                    //if selected, then connect to the device
                    .onTapGesture {
                        print("Selected device: \(device.name)")

                        //the things we want to talk to in our peripheral
                        let writeChar = ParticleBLECharacteristic(characteristic: CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"), type: CBCharacteristicProperties.write)
                        
                        //set .read, .notify
                        var readNotify = CBCharacteristicProperties()
                        readNotify.insert(.read)
                        readNotify.insert(.notify)

                        let readChar = ParticleBLECharacteristic(characteristic: CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"), type: readNotify)
                        
                        particleBLEScanningObservable.connect(peripheral: device.peripheral!, characteristics: [writeChar, readChar])
                    }

                    
                }
                .onAppear() {
                    particleBLEScanningObservable.setDelegate(delegate: self)
                    particleBLEScanningObservable.startBLERunning(serviceUUID: serviceUUID)
                }
                ProgressView()
                    .padding()
                    .shadow(color: Color(red: 0, green: 0, blue: 0.6),
                                        radius: 4.0, x: 1.0, y: 2.0)
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

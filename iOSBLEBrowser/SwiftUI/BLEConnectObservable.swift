//
//  ParticleBLEScanningObservable.swift
//  iOSBLEBrowser
//
//  Created by Nick Lambourne on 10/20/22.
//
// This class is used by SwiftUI components to observe changes going on in the underlying BLE protocol
// It also acts as a proxy for commands being sent to the device so when the result of the API call is ready,
// the class can observe the updated data and merge it into the UI layer

import Foundation
import CoreBluetooth

protocol ParticleBLEConnectObservableDelegate {
    func connectionUpdate()
}

class ParticleBLEConnectObservableDevice {
    var uuid: String = "";
    var state: ParticleBLEConnectedDevice.State = .disconnected;
}

class ParticleBLEConnectObservable: ObservableObject, ParticleBLEConnectStatusDelegate, ParticleBLEConnectDataDelegate, ParticleBLEPeripheralStatusDelegate, ParticleBLEPeripheralStatusDelegate {

    init() {
        connectingDevices = []
        
        ParticleBLEExampleGlobals.particleBLEConnectInstance.registerStatusDelegate(delegate: self)
        ParticleBLEExampleGlobals.particleBLEConnectInstance.registerDataDelegate(delegate: self)
        
        ParticleBLEExampleGlobals.particleBLEConnectInstance.registerPeripheralStatusDelegate(delegate: self)
        ParticleBLEExampleGlobals.particleBLEConnectInstance.registerPeripheralStatusDelegate(delegate: self)
    }

    func onDataReceived(peripheral: CBPeripheral, data: [UInt8]) {
        
    }

    func onStatusUpdated(peripheral: CBPeripheral, state: ParticleBLEConnectedDevice.State) {
        var connectingDevicesCopy = connectingDevices;
        
        //is our peripheral already in our list?
        if let index = connectingDevicesCopy.firstIndex(where: { $0.uuid == peripheral.identifier.uuidString }) {
            connectingDevicesCopy[index].state = state
        }
        else {
            let newDevice = ParticleBLEConnectObservableDevice()
            newDevice.uuid = peripheral.identifier.uuidString
            newDevice.state = state
            connectingDevicesCopy.append(newDevice)
        }

        //update the list
        connectingDevices = connectingDevicesCopy
    }

    //These published variables automatically redraw any swift UI observers that are listening
    @Published var connectingDevices: [ParticleBLEConnectObservableDevice] {
        didSet {
            //nothing
        }
    }
    
    func startup() {
        ParticleBLEExampleGlobals.particleBLEConnectInstance.startup()
    }

    //these functions can call the BLE iOS system wide prompt to pop up
    //NOT HANDLED:
    // - user permission denied
    // - user permission revoked
    func connect(peripheral: CBPeripheral, characteristics: [ParticleBLECharacteristic] ) {
        
        //this will cause BLE to be turned on. Its a good place to prime the user for the permissions dialog
        ParticleBLEExampleGlobals.particleBLEConnectInstance.connect(peripheral: peripheral, characteristics: characteristics)
    }
}

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

protocol ParticleBLEScanningObservableDelegate {
    func stateUpdated()
}

class ParticleBLEScanningObservableDevice {
    var name: String = "";
    var uuid: String = "";
    
    var peripheral: CBPeripheral? = nil;
    var state: ParticleBLEConnectedDevice.State = .disconnected;
}

class ParticleBLEScanningObservable: ObservableObject, ParticleBLEScannerStatusDelegate, ParticleBLEDeviceFoundDelegate, ParticleBLEPeripheralDataDelegate, ParticleBLEPeripheralStatusDelegate {

    var delegate: ParticleBLEScanningObservableDelegate? = nil

    var internalDiscoveredPeripherals: [String: CBPeripheral] = [:]

    init() {
        internalDiscoveredPeripherals = [:]
        bleInterfaceStateAsTextString = "Idle"
        
        discoveredPeripherals = []
        
        ParticleBLEExampleGlobals.particleBLEScannerInstance.registerScanningStatusDelegate(delegate: self)
        ParticleBLEExampleGlobals.particleBLEScannerInstance.registerDeviceFoundDelegate(delegate: self)
        
        ParticleBLEExampleGlobals.particleBLEScannerInstance.registerPeripheralStatusDelegate(delegate: self)
        ParticleBLEExampleGlobals.particleBLEScannerInstance.registerDataDelegate(delegate: self)

    }
    
    func setDelegate(delegate: ParticleBLEScanningObservableDelegate) {
        self.delegate = delegate
    }
    
    func onStatusUpdated(state: ParticleBLEScannerAbstract.ScanningState) {
        //bleInterfaceStateAsTextString = interfaceState.rawValue
        
        if delegate != nil {
            delegate?.stateUpdated()
        }
    }
    
    func onDeviceFound(peripheral: CBPeripheral) {
        let uuid = peripheral.identifier.uuidString
        if internalDiscoveredPeripherals[uuid] == nil {
            internalDiscoveredPeripherals[uuid] = peripheral
            print("Discovered new peripheral: \(peripheral.name ?? "Unknown") with UUID: \(uuid)")
        } else {
            print("Peripheral already discovered: \(peripheral.name ?? "Unknown") with UUID: \(uuid)")
        }

        //update all devices
        var allDevicesStaging : [ParticleBLEScanningObservableDevice] = []
        for (uuid, peripheral) in internalDiscoveredPeripherals {
            let device = ParticleBLEScanningObservableDevice()
            device.name = peripheral.name ?? "Unknown"
            device.uuid = uuid
            device.peripheral = peripheral
            allDevicesStaging.append(device)
        }
        discoveredPeripherals = allDevicesStaging;
    }
    
    func onDataReceived(peripheral: CBPeripheral, data: [UInt8]) {
        //do nothing currently...
    }

    func onStatusUpdated(peripheral: CBPeripheral, state: ParticleBLEConnectedDevice.State) {
        var discoveredPeripheralsCopy = discoveredPeripherals;
        
        //is our peripheral already in our list?
        if let index = discoveredPeripheralsCopy.firstIndex(where: { $0.uuid == peripheral.identifier.uuidString }) {
            discoveredPeripheralsCopy[index].state = state
        }
        else {
            //how did we connect to a device not on our list?!
            assert( false )
        }

        //update the list
        discoveredPeripherals = discoveredPeripheralsCopy
    }
    
    //These published variables automatically redraw any swift UI observers that are listening
    @Published var discoveredPeripherals: [ParticleBLEScanningObservableDevice] {
        didSet {
            //nothing
        }
    }
        
    @Published var bleInterfaceStateAsTextString: String {
        didSet {
            //nothing
        }
    }
        
    //these functions can call the BLE iOS system wide prompt to pop up
    //NOT HANDLED:
    // - user permission denied
    // - user permission revoked
    func startBLERunning(serviceUUID: String) {
        
        //TODO - stop the below lines from running on a retry...
        
        //this will cause BLE to be turned on. Its a good place to prime the user for the permissions dialog
        ParticleBLEExampleGlobals.particleBLEScannerInstance.startScanning(serviceUUID: serviceUUID ) {
            ParticleBLEExampleGlobals.particleBLEScannerInstance.startScanning()
        }
    }
    
    func stopBLE() {
        ParticleBLEExampleGlobals.particleBLEScannerInstance.stopScanning()
    }
    
    func connect(peripheral: CBPeripheral, characteristics: [ParticleBLECharacteristic] ) {
        
        //this will cause BLE to be turned on. Its a good place to prime the user for the permissions dialog
        ParticleBLEExampleGlobals.particleBLEScannerInstance.connect(peripheral: peripheral, characteristics: characteristics)
    }
    
    func sendBuffer(peripheral: CBPeripheral, characteristic: ParticleBLECharacteristic, buffer: [UInt8] ) {
        ParticleBLEExampleGlobals.particleBLEScannerInstance.sendBuffer(peripheral: peripheral, characteristic: characteristic, buffer: buffer)
    }
}

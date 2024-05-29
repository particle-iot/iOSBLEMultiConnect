//
//  ParticleBLEInterfaceAbstract.swift
//  iOSBLEBrowser
//
//  Created by Nick Lambourne on 11/27/22.
//

import Foundation
import CoreBluetooth

// // // // // // // // // //
//Scanner
// // // // // // // // // //

protocol ParticleBLEScannerStatusDelegate {
    func onStatusUpdated(state: ParticleBLEScanner.ScanningState)
}

protocol ParticleBLEDeviceFoundDelegate {
    func onDeviceFound(peripheral: CBPeripheral)
}


// // // // // // // // // //
//Peripherals
// // // // // // // // // //

//a class that holds our verison of the CBPeripheral
//it includes:
// state
// a list of characteristics and their CBCharacteristic
public class ParticleBLEConnectedDevice {
    var peripheral: CBPeripheral
    var state: State
    var characteristics: [ParticleBLECharacteristic]
    var foundCharacteristics: [String : CBCharacteristic?]

    enum State: String, Codable {
        case disconnected
        case connecting
        case connectingDiscoveringCharacterstics
        case connected
    }

    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.characteristics = []
        self.state = .disconnected
        self.foundCharacteristics = [:]
    }
}

public class ParticleBLECharacteristic: Hashable {
    var identifier: String {
        return characteristic.uuidString
    }
  
    var characteristic: CBUUID
    var type: CBCharacteristicProperties
    
    init(characteristic: CBUUID, type: CBCharacteristicProperties) {
        self.characteristic = characteristic
        self.type = type
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(identifier)
    }

    public static func == (lhs: ParticleBLECharacteristic, rhs: ParticleBLECharacteristic) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

protocol ParticleBLEPeripheralDataDelegate {
    func onDataReceived(peripheral: CBPeripheral, data: [UInt8])
}

protocol ParticleBLEPeripheralStatusDelegate {
    func onStatusUpdated(peripheral: CBPeripheral, state: ParticleBLEConnectedDevice.State)
}


public class ParticleBLEScannerAbstract : NSObject {
    
    // // // // // // // // // //
    //Scanner
    // // // // // // // // // //
    enum ScanningState: String, Codable {
        case idle
        case lookingForDevices
    }
    
    var scanningState: ScanningState = .idle

    var statusUpdatedDelegate:[ParticleBLEScannerStatusDelegate] = []
    var deviceFoundDelegate:[ParticleBLEDeviceFoundDelegate] = []
    
    func registerDeviceFoundDelegate( delegate: ParticleBLEDeviceFoundDelegate ) {
        deviceFoundDelegate.append( delegate )
    }
    
    func informDelegatesOfNewDevice(peripheral: CBPeripheral) {
        for d in deviceFoundDelegate {
            d.onDeviceFound(peripheral: peripheral)
        }
    }
    
    func registerScanningStatusDelegate( delegate: ParticleBLEScannerStatusDelegate ) {
        statusUpdatedDelegate.append( delegate )
    }

    func informDelegatesOfScanningStatusUpdate(state: ScanningState) {
        for d in statusUpdatedDelegate {
            d.onStatusUpdated( state: state )
        }
    }
    
    func startScanning(serviceUUID: String, completionHandler: @escaping () -> Void) {
        assert( false )
    }
    
    func stopScanning() {
        assert( false )
    }
    
    // // // // // // // // // //
    //Peripherals
    // // // // // // // // // //
    var peripheralState: [CBPeripheral : ParticleBLEConnectedDevice] = [:]
    
    //delegate list
    var statusDelegates:[ParticleBLEPeripheralStatusDelegate] = []
    var dataDelegates:[ParticleBLEPeripheralDataDelegate] = []
    
    func registerDataDelegate( delegate: ParticleBLEPeripheralDataDelegate ) {
        dataDelegates.append( delegate )
    }
    
    func informDelegatesOfDataAvailable(peripheral: CBPeripheral,data: [UInt8]) {
        for d in dataDelegates {
            d.onDataReceived(peripheral: peripheral, data: data)
        }
    }
    
    func registerPeripheralStatusDelegate( delegate: ParticleBLEPeripheralStatusDelegate ) {
        statusDelegates.append( delegate )
    }

    func informDelegatesOfPeripheralStatusUpdate(peripheral: CBPeripheral, state: ParticleBLEConnectedDevice.State) {
        for d in statusDelegates {
            d.onStatusUpdated(peripheral: peripheral, state: state )
        }
    }

    //connect passes in a peripheral and a list of characteristics to discover
    //these charactersitics include their types (read, write, notify, etc)
    //return ParticleBLEConnectedDevice? from this function
    func connect(peripheral: CBPeripheral, characteristics: [ParticleBLECharacteristic]) -> ParticleBLEConnectedDevice? {
        assert( false )
        return nil;
    }
    
    func disconnect(peripheral: CBPeripheral) {
        assert( false )
    }
    
    func sendBuffer(peripheral: CBPeripheral, characteristic: ParticleBLECharacteristic, buffer: [UInt8]) {
        assert( false )
    }
}

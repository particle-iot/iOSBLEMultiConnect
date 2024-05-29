//
//  ParticleBLE.swift
//  iOSBLEBrowser
//
//  Created by Nick Lambourne on 10/20/22.
//

import Foundation
import CoreBluetooth
import NIOCore

class ParticleBLEScanner: ParticleBLEScannerAbstract {
    
    ///
    /// Variables
    ///

    var bleScanning: Bool = false

    var startupCompletionHandler: (() -> Void)? = nil

    //The bluetooth bits
    var centralManager: CBCentralManager!

    //device details
    var serviceUUID: String = ""
    
    ///
    /// Public funcs for Scanning
    ///
    
    //an explicit startup command is needed (vs an init) because this can prompt the user for permissions
    override func startScanning(serviceUUID: String, completionHandler: @escaping () -> Void) {
        self.serviceUUID = serviceUUID
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        //store the completionHandler for when the BLE interface turns on.
        startupCompletionHandler = completionHandler
    }
    
    func startScanning() {
        updateState(state: .lookingForDevices)
    }
    
    override func stopScanning() {
        //always go back to idlef
        updateState(state: .idle)
    }

    ///
    /// Public funcs for Peripherals
    ///
    
    //an explicit startup command is needed (vs an init) because this can prompt the user for permissions
    override func connect(peripheral: CBPeripheral, characteristics: [ParticleBLECharacteristic]) -> ParticleBLEConnectedDevice? {
        //check this peripheral is not already in my list
        if peripheralState[peripheral] == nil {

            //create a new ble device
            let newDevice = ParticleBLEConnectedDevice(peripheral: peripheral)
            
            newDevice.characteristics = characteristics

            self.centralManager.connect(peripheral)

            //set the connecting state
            newDevice.state = .connecting

            //add to the list
            peripheralState[peripheral] = newDevice

            //notify the delegates
            informDelegatesOfPeripheralStatusUpdate(peripheral: peripheral, state: newDevice.state)

            return peripheralState[peripheral]
        }
        else {
            //if this already exists but we are disconnected, try and connect again
            if( peripheralState[peripheral]!.state == .disconnected ) {
                self.centralManager.connect(peripheral)
                
                peripheralState[peripheral]?.state = .connecting
                
                //notify the delegates
                informDelegatesOfPeripheralStatusUpdate(peripheral: peripheral, state: peripheralState[peripheral]!.state)

                return peripheralState[peripheral]
            }
        }

        return nil;
    }
    
    override func disconnect(peripheral: CBPeripheral) {
        //check this peripheral is in my list
        if peripheralState[peripheral] != nil {

            //am I connected or connecting?
            if peripheralState[peripheral]!.state == .connected || peripheralState[peripheral]!.state == .connecting || peripheralState[peripheral]!.state == .connectingDiscoveringCharacterstics {
                //disconnect
                self.centralManager.cancelPeripheralConnection(peripheral)
            }
            else {
                assert( false )
            }
        }
    }
    
    override func sendBuffer(peripheral: CBPeripheral, characteristic: ParticleBLECharacteristic, buffer: [UInt8]) {
        let maxPacketSize: Int? = peripheral.maximumWriteValueLength(for: .withoutResponse)
       
        var bufferSize = buffer.count
        var currentOffset = 0
        var currentMaxLimit = min( maxPacketSize!, bufferSize )
        
        print("BLE sendBuffer: \(buffer.count)")
        
        //find the rxCharacteristic that has the write flags from our list and send the buffer
        var rxCharacteristicOurs : String = "";
        var rxCharacteristiciOS : CBCharacteristic? = nil;
        
        //go through peripheralState[peripheral]?.characteristics and find the one with a .write flag
        for c in peripheralState[peripheral]!.characteristics {

            //see if it matches characteristic as passed in
            if c.characteristic.uuidString == characteristic.characteristic.uuidString {
                //check its valid to write to
                if c.type.contains(.write) {
                    rxCharacteristicOurs = c.characteristic.uuidString
                }
            }
        }
  
        //now find the iOS one
        for c in peripheralState[peripheral]!.foundCharacteristics {
            if c.key == rxCharacteristicOurs {
                rxCharacteristiciOS = c.value
            }
        }
        
        while bufferSize != 0 {
            
            print("BLE sendBuffer Chunk: \(currentOffset) \(currentMaxLimit)")
            
            peripheral.writeValue(Data(buffer[currentOffset...(currentMaxLimit-1)]), for: rxCharacteristiciOS!, type: .withoutResponse)
            
            let dataJustSent = (currentMaxLimit - currentOffset)
            bufferSize -= dataJustSent
            currentOffset += dataJustSent
            
            if bufferSize != 0 {
                let nextRound = (bufferSize > maxPacketSize! ? maxPacketSize! : bufferSize)
                currentMaxLimit = currentOffset + nextRound
            }
        }
    }
    
    ///
    /// Private functions
    ///

    private func updateState( state: ScanningState ) {
        
        print("updateState(\(state))")
        
        //gotta be a new state, right?
        assert(self.scanningState != state)

        var scanBLE: Bool = false

        switch state {
            case .lookingForDevices:
                scanBLE = true
    
            case .idle:
                scanBLE = false
            
            default:
                assert( false )
        }
        
        //BLE scanning changes
        if scanBLE && !bleScanning {
            print("Starting BLE scanning")
            centralManager.scanForPeripherals(withServices: [], options: [CBCentralManagerScanOptionAllowDuplicatesKey : false] )
        }
        if !scanBLE && bleScanning {
            print("Stopping BLE scanning")
            centralManager.stopScan()
        }
        bleScanning = scanBLE
        
        //store the new state
        self.scanningState = state
        
        //inform the delegates!
        informDelegatesOfScanningStatusUpdate(state: state)
    }
}


extension ParticleBLEScanner: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .unknown:
                print("central.state is .unknown")
            case .resetting:
                print("central.state is .resetting")
            case .unsupported:
                print("central.state is .unsupported")
            case .unauthorized:
                print("central.state is .unauthorized")
            case .poweredOff:
                print("central.state is .poweredOff")
            case .poweredOn:
                print("central.state is .poweredOn")
                if startupCompletionHandler != nil {
                    startupCompletionHandler!()
                    startupCompletionHandler = nil
                }
            @unknown default:
                print("central.state is .unknown")
        }
    }

    func getManufacturingData( advertisementData: [String: Any] ) throws -> (companyID: UInt16, platformID: UInt16, setupCode: String) {
        //did we find our peripheral? our peripheral has manufacturing data!
        
        var companyID: UInt16 = 0
        var platformID: UInt16 = 0
        var setupCode: String = ""
        
        if let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data {
            assert(manufacturerData.count == (2 + 2 + 6))
            
            let allocator = ByteBufferAllocator()
            var buf: ByteBuffer! = nil
            buf = allocator.buffer(capacity: manufacturerData.count)
            buf.writeBytes(Array(manufacturerData))
            
            companyID = buf.readInteger(endianness: .little)!
            //print("companyID", String(format: "%04X", companyID))
            
            platformID = buf.readInteger(endianness: .little)!
            //print("platformID", String(format: "%04X", platformID))
            
            setupCode = buf.readString(length: 6)!
            //print("setupCode: \(setupCode)")
        }

        return (companyID, platformID, setupCode )
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {

        //print out the advertisement uuid
        if let advertisementUUIDs = advertisementData["kCBAdvDataServiceUUIDs"] as? [CBUUID] {
            for uuid in advertisementUUIDs {
                print("advertisementUUIDs: \(uuid)")
                print("looking for \(serviceUUID)")
    
    //            guard let name = peripheral.name else { "unknown" }
    //            print("name: \(name)")
                
                if serviceUUID == uuid.uuidString {
                    if( self.scanningState == .lookingForDevices ) {
                        informDelegatesOfNewDevice(peripheral: peripheral)
                    }
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect(\(peripheral))")
        peripheral.delegate = self
        peripheral.discoverServices(nil)

        //update the state
        if peripheralState[peripheral]?.state == .connecting {
            peripheralState[peripheral]?.state = .connectingDiscoveringCharacterstics

            //notify the delegates
            informDelegatesOfPeripheralStatusUpdate(peripheral: peripheral, state: .connectingDiscoveringCharacterstics)
        }
        else {
            assert( false )
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnect(\(peripheral))")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral(\(peripheral))")

        //update the state if we know about htis
        if peripheralState[peripheral] != nil {
            peripheralState[peripheral]?.state = .disconnected

            //notify the delegates
            informDelegatesOfPeripheralStatusUpdate(peripheral: peripheral, state: .disconnected)
        }
    }
}


extension ParticleBLEScanner: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        print("didDiscoverIncludedServicesFor(\(service)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("didDiscoverCharacteristicsFor(\(service)")

        //check we know about this peripheral
        if peripheralState[peripheral] != nil {
            
            print(service.characteristics!)
            
            for c in service.characteristics! {
                print(c)
            }
            
            for c in peripheralState[peripheral]!.characteristics {
                print(c.characteristic.uuidString)
            }

            //check if the characteristics match our peripherals characteristics
            //if so, store the CBCharacteristic along with the uuid string in foundCharacteristics
            for c in service.characteristics! {
                if peripheralState[peripheral]!.characteristics.contains(where: { $0.characteristic.uuidString == c.uuid.uuidString }) {
                    peripheralState[peripheral]!.foundCharacteristics[c.uuid.uuidString] = c
                }
            }

            //if we have found all the characteristics we are looking for, we are connected
            if peripheralState[peripheral]!.foundCharacteristics.count == peripheralState[peripheral]!.characteristics.count {
                peripheralState[peripheral]?.state = .connected
                
                //register for notifications from the one with notify as a characteristic property
                for c in peripheralState[peripheral]!.characteristics {
                    if c.type.contains(.notify) {
                        peripheral.setNotifyValue(true, for: peripheralState[peripheral]!.foundCharacteristics[c.characteristic.uuidString]!!)
                    }
                }

                //notify the delegates
                informDelegatesOfPeripheralStatusUpdate(peripheral: peripheral, state: .connected)
            }
            else {
                //disconnect
                self.centralManager.cancelPeripheralConnection(peripheral)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("didDiscoverServices(\(String(describing: error))")
        for s in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: s)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateValueFor(\(characteristic)")
        
        //decode and send back
        if let data = characteristic.value {
            informDelegatesOfDataAvailable(peripheral: peripheral, data: Array(data))
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didWriteValueFor(\(characteristic)")
    }
}

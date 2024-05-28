/* 
 * Project myProject
 * Author: Your Name
 * Date: 
 * For comprehensive documentation and examples, please visit:
 * https://docs.particle.io/firmware/best-practices/firmware-template/
 */

// Include Particle Device OS APIs
#include "Particle.h"

// Let Device OS manage the connection to the Particle Cloud
SYSTEM_MODE(SEMI_AUTOMATIC);

// Run the application and system concurrently in separate threads
SYSTEM_THREAD(ENABLED);

// Show system, cloud connectivity, and application logs over USB
// View logs with CLI using 'particle serial monitor --follow'
SerialLogHandler logHandler(LOG_LEVEL_INFO);

const char* serviceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
const char* rxUuid = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
const char* txUuid = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";

//define onDataReceived
void onDataReceived(const uint8_t* data, size_t len, const BlePeerDevice& peer, void* context) {
    Log.info("Data (%d bytes):", len);
    Log.info("%.*s", len, data);
}

BleCharacteristic txCharacteristic("tx", BleCharacteristicProperty::NOTIFY, txUuid, serviceUuid);
BleCharacteristic rxCharacteristic("rx", BleCharacteristicProperty::WRITE_WO_RSP, rxUuid, serviceUuid, onDataReceived, NULL);

STARTUP(System.enableFeature(FEATURE_DISABLE_LISTENING_MODE));

// setup() runs once, when the device is first turned on
void setup() {

    //turn on BLE and configure a device to have two characteristics.
    // 1. is a read characteristic that contains max available payload size
    // 2. is a write characteristic that can be used to send data to the device

    //log to say hellow
    Log.info("Starting BLE peripheral");

    BLE.provisioningMode(false);

    BLE.on();
    WiFi.off();

    //advertise using the service UUID and include the characteristics
    BleAdvertisingData advData;
    advData.clear();
    advData.appendServiceUUID(serviceUuid);

    //add the name "partible" to the device
    advData.appendLocalName("partible");

    //get the length of the data
    Log.info("Advertising data length: %d", advData.length());

    //remove all the characteristics from the device

    //add the characteristics to the device
    BLE.addCharacteristic(txCharacteristic);
    BLE.addCharacteristic(rxCharacteristic);

    // Set up advertising parameters
    BleAdvertisingParams advParams;
    BLE.getAdvertisingParameters(advParams); 
    advParams.interval *= 4;
    BLE.setAdvertisingParameters(&advParams); // Apply the advertising parameters
    Log.info("Advertising interval: %d", advParams.interval);

    BLE.advertise(&advData);

    Log.info("BLE peripheral started");
}

// loop() runs over and over again, as quickly as it can execute.
void loop() {
  //every 10 seconds, print out the BLE status
  Log.info("BLE status: %d", BLE.connected());
  delay(10000);
}

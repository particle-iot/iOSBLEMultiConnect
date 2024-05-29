# iOSBLEMultiConnect

An example of how to communicate to a Particle module over the BLE interface with multiple BLE peripherals attached at once.

Setup:
- Multiple Particle devices. Tested was a Photon 2, but you can use Argons, P2's, M-SoMs etc... 
- Flash the firmware in firmware/ble_peripheral to each device. Make sure that device was setup on setup.particle.io if its new!
- power on the device. The devices should appear in the list! click on one to connect to it. The connection light should go grey to orange and then green when it connects
- press the device again to toggle its LED!

Tech notes:
- the UI is written in Swift UI. Accordingly, BLEScanningObservable sits in between the classes to observe the changes and paint the UI state
- the project is called iOSBLEBrowser at the moment - it needes updating to iOSBLEMultiConnect but you get the drift :)
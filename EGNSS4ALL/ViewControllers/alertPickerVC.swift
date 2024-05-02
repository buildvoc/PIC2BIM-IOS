//
//  alertPickerVC.swift
//  EGNSS4ALL
//
//  Created by ERASMICOIN on 20/09/22.
//

import UIKit
import CoreBluetooth

protocol alertPickerDelegate {
    func onCancel()
}



class alertPickerVC: UIViewController, UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate {
    
    var delegate:alertPickerDelegate?
    var peripherals:[CBPeripheral] = []
    var localStorage = UserDefaults.standard
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var tableObject: UITableView!
    
    @IBAction func cancAction(_ sender: UIButton) {
        self.delegate?.onCancel()
        self.dismiss(animated: true, completion: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral.debugDescription)
        self.peripherals.append(peripheral)
        self.tableObject.reloadData()
        
        if peripheral.identifier.uuidString == periphealUUID.uuidString {
            myPeripheal = peripheral
            myPeripheal?.delegate = self
            manager?.connect(myPeripheal!, options: nil)
            manager?.stopScan()
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            
            print("Bluetooth disattivato")
        case .poweredOn:
            
            print("Bluetooth attivo")
            manager?.scanForPeripherals(withServices:[serviceUUID], options: nil)
        case .unsupported:
           
            print("Bluetooth non è supportato")
        default:
            
            print("Stato sconosciuto")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([serviceUUID])
        print("Connesso a " +  peripheral.name!)
        
        //self.alertStandard(titolo: "External GNSS", testo: "Connected")
    
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnesso da " +  peripheral.name!)
        
        self.alertStandard(titolo: "WARNING", testo: "External GNSS Disconnected")
       
        myPeripheal = nil
        myCharacteristic = nil
    
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print(error!)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(peripherals.count)
        return peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell.init(style: .value1, reuseIdentifier: "cell")
        let device = peripherals[indexPath.row]
        let strUUID = device.identifier.uuidString
        let truncUUID = strUUID[...7]
        cell.textLabel?.text = "\(device.name ?? "Unknown")    (\(truncUUID))"
        cell.textLabel?.font = UIFont(name: "Metropolis-SemiBold", size: 16)
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = UIColor(named: "dark")
        cell.detailTextLabel?.textColor = UIColor(named: "dark")
        cell.backgroundColor = .clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //let oggetto = oggetti![indexPath.row]
        //delegate?.onSelectData(professione: oggetto)
        self.localStorage.set(true, forKey: "externalGPS")
        self.localStorage.set(peripherals[indexPath.row].identifier.uuidString, forKey: "periphealUUID")
        let selPeriphealUUID = localStorage.string(forKey: "periphealUUID")
        periphealUUID = CBUUID(string: peripherals[indexPath.row].identifier.uuidString)
        peripherals.removeAll()
        manager?.scanForPeripherals(withServices:[serviceUUID], options: nil)
        //self.dismiss(animated: true, completion: nil)
    }
    

    override func viewDidLoad() {
        
        manager = CBCentralManager(delegate: self, queue: nil)
        
        
        tableObject.backgroundColor = .clear
        
        //cancelBtn.btnStandard(label: "Cancel", color: "background")
        
        containerView.layer.backgroundColor = UIColor(named: "background")?.cgColor
        containerView.layer.cornerRadius = 8
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 3)
        containerView.layer.shadowOpacity = 0.42
        containerView.layer.shadowRadius = 4
        
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension alertPickerVC: CBPeripheralDelegate {
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        print(peripheral.debugDescription)
        
       
        
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
            
            
        }
        
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        //print(characteristic.debugDescription)
       
        //self.getNavSat(characteristic: characteristic)
        //NO
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //print(characteristic.debugDescription)
        //print("update")
        //self.recordFunc()
        
        if characteristic == myCharacteristic {
            //print("update sfrbx")
            //self.addSat(characteristic: characteristic)
        }
        
        if characteristic == navCharacteristic {
            //self.getNavSat(characteristic: characteristic)
        }
        
        if characteristic == pvtCharacteristic {
            //self.getNavPvt(characteristic: characteristic)
        }
        
        if characteristic == telCharacteristic {
            //self.getTelemetry(characteristic: characteristic)
        }
       
        //NO
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        
       //NO
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        //print(characteristic.debugDescription)
        print(characteristic.debugDescription)
    }
   
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        myCharacteristic = characteristics[0]
        telCharacteristic = characteristics[1]
        navCharacteristic = characteristics[2]
        pvtCharacteristic = characteristics[3]
       
        myPeripheal?.setNotifyValue(true, for: pvtCharacteristic!)
        myPeripheal?.setNotifyValue(true, for: myCharacteristic!)
        myPeripheal?.setNotifyValue(true, for: telCharacteristic!)
        myPeripheal?.setNotifyValue(true, for: navCharacteristic!)
        
        
        self.dismiss(animated: true)

    }
}

public extension String {
  subscript(value: Int) -> Character {
    self[index(at: value)]
  }
}

public extension String {
  subscript(value: NSRange) -> Substring {
    self[value.lowerBound..<value.upperBound]
  }
}

public extension String {
  subscript(value: CountableClosedRange<Int>) -> Substring {
    self[index(at: value.lowerBound)...index(at: value.upperBound)]
  }

  subscript(value: CountableRange<Int>) -> Substring {
    self[index(at: value.lowerBound)..<index(at: value.upperBound)]
  }

  subscript(value: PartialRangeUpTo<Int>) -> Substring {
    self[..<index(at: value.upperBound)]
  }

  subscript(value: PartialRangeThrough<Int>) -> Substring {
    self[...index(at: value.upperBound)]
  }

  subscript(value: PartialRangeFrom<Int>) -> Substring {
    self[index(at: value.lowerBound)...]
  }
}

private extension String {
  func index(at offset: Int) -> String.Index {
    index(startIndex, offsetBy: offset)
  }
}


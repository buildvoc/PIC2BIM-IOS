//
//  ViewController.swift
//  EGNSS4CAP
//
//  
//

import UIKit
import CoreLocation
import CoreData
import CoreBluetooth
import Lottie

var myPeripheal:CBPeripheral?
var myCharacteristic:CBCharacteristic?
var telCharacteristic:CBCharacteristic?
var navCharacteristic:CBCharacteristic?
var pvtCharacteristic:CBCharacteristic?
var manager:CBCentralManager?
var peripherals:[CBPeripheral] = []

var navSatData = [Int: [Int: Satellite]]()
var satelliti = [Satellite]()
var navPVTData = [String: Any]()
var telemetryData = [String: Any]()
var sfrbxArray: NSMutableArray = []

let serviceUUID = CBUUID(string: "")
var periphealUUID = CBUUID(string: "")
let animationView = LottieAnimationView(name: "egnss4all_anitest")

class MainViewController: UIViewController, CBCentralManagerDelegate {
    
    var manageObjectContext: NSManagedObjectContext!

    
    @IBOutlet weak var userView: UIView!
    @IBOutlet weak var basicInfoView: UIView!
    @IBOutlet weak var loginLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var surnameLabel: UILabel!
    @IBOutlet weak var locationCheckImage: UIImageView!
    @IBOutlet weak var galileoCheckImage: UIImageView!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var serviceView: UIView!
    @IBOutlet weak var galileoView: UIView!
    
    @IBOutlet weak var animView: UIView!
    
    @IBAction func infoAction(_ sender: UIButton) {
        animView.isHidden = true
    }
    let locationManager = CLLocationManager()
    private var timer: Timer!
    var timerNavPvt = Timer()
    
    let localStorage = UserDefaults.standard
    
    func triggerPvt() {
        let str = "getNavPvt"
        
        let data = Data(str.utf8)
        if myPeripheal == nil { return }
        if pvtCharacteristic == nil { return }
        
        myPeripheal!.writeValue(data, for: pvtCharacteristic!, type: .withResponse)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral.debugDescription)
        
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
            
            print("Bluetooth disabled")
        case .poweredOn:
            let extGPS = localStorage.bool(forKey: "externalGPS")
            
            
            if extGPS {
                manager?.scanForPeripherals(withServices:[serviceUUID], options: nil)
            }
            
            print("Bluetooth enabled")
        case .unsupported:
           
            print("Bluetooth not supported")
        default:
            
            print("unknown state")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([serviceUUID])
        print("connected to " +  peripheral.name!)
        
        
        
    
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnected from " +  peripheral.name!)
        self.alertStandard(titolo: "WARNING", testo: "External GNSS Disconnected")
        myPeripheal = nil
        myCharacteristic = nil
    
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print(error!)
    }
    
    func addSat(characteristic: CBCharacteristic) {
        
        if (myPeripheal != nil) {
            //myPeripheal!.readValue(for: myCharacteristic!)
            
            if characteristic.value != nil {
                //print(String(decoding: characteristic.value!, as: UTF8.self))
                
                
                let str = String(decoding: characteristic.value!, as: UTF8.self)
                let data = Data(str.utf8)
                

                do {
                    // make sure this JSON is in the format we expect
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        // try to read out a string array
                        
                        let sat = Satellite.downloadSingleSat(jsonArray: json)
                           
                            if sat.gnssId == 2 && sat.dwrd![5] as! Int > 42 {
                                let actSat = satelliti.first(where: { $0.gnssId == sat.gnssId && $0.id == sat.id })
                                if  actSat != nil {
                                    if (Int(Date().timeIntervalSince1970) > actSat!.timestamp! + 310 || actSat?.stato == false)  {
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
                                            
                                            let uuidSmartphone = UIDevice.current.identifierForVendor!.uuidString
                                            let json = ["uuid": uuidSmartphone, "uuidExt": "DVLGNSS2A001", "svId": sat.id!, "gnssId": 2, "source": "client", "numWords": 8, "version": sat.versione, "iTow": sat.iTow!, "timestamp": sat.timestamp, "manufacturer": sat.manufacturer!, "model": sat.model, "dwrd0": sat.dwrd![0], "dwrd1": sat.dwrd![1], "dwrd2": sat.dwrd![2], "dwrd3": sat.dwrd![3], "dwrd4": sat.dwrd![4], "dwrd5": sat.dwrd![5], "dwrd6": sat.dwrd![6], "dwrd7": sat.dwrd![7]] as [String : Any]
                                            
                                            
                                            if NetworkManager.shared.isNetworkAvailable() {
                                                print("Network ok")
                                                if sfrbxArray.count != 0 {
                                                    self.validateOffline(json: sfrbxArray[0])
                                                }
                                                self.validate(sat: sat)
                                            } else {
                                                print("Network not ok, save sfrbx")
                                                
                                                sfrbxArray.add(json)
                                                
                                                return
                                                
                                            }
                                            
                                        
                                        })
                                    }
                                } else {
                                    satelliti.append(sat)
                                    
                                    
                                    
                                    if sat.dwrd![5] as! Int > 42 {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
                                            if NetworkManager.shared.isNetworkAvailable() {
                                                print("Network ok")
                                                if sfrbxArray.count != 0 {
                                                    self.validateOffline(json: sfrbxArray[0])
                                                }
                                                self.validate(sat: sat)
                                            } else {
                                                print("Network not ok, save sfrbx")
                                                
                                                sfrbxArray.add(json)
                                                
                                                return
                                                
                                            }
                                        })
                                    }
                                   
                                }
                                
                            }
                           
                           
                        
                        
                    }
                                
                } catch let error as NSError {
                    //print("qui")
                    print("Failed to load: \(error.localizedDescription)")
                    
                }
                
                
            }
            
        }
        
        
        
    }
    
    func validateOffline(json: Any) {
        
        
        
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        var request = URLRequest(url: URL(string: "yourserverurl")!)
        
        request.allHTTPHeaderFields = ["X-Parse-Application-Id": "appId", "X-Parse-REST-API-Key": "yourrestapikey"]
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData
       
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async(execute: { // controllo problemi di network
                    self.alertStandard(titolo: "WARNING", testo: "Network connection error")
                })
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // controllo errore                print("il codice dovrebbe essere 200, ma è \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            
            DispatchQueue.main.async(execute: {
                if let jsonDictionary = NetworkService.parseJSONFromData(data as Data) {

                    let dictionary = jsonDictionary["result"]
                    let satId: Int = dictionary!["svId"] as? Int ?? 0
                    let esitoValidazione: Bool = dictionary!["valid"] as! Bool
                    let osnmaStr = dictionary!["osnma"] as! String
                    let validTimeStamp = dictionary!["timestamp"] as? Int ?? 0
                
                }
            })
            
            sfrbxArray.removeObject(at: 0)

        }
        task.resume()
    }
    
    func validate(sat: Satellite) {
        
        sat.check(state: 2)
        let uuidSmartphone = UIDevice.current.identifierForVendor!.uuidString
        let json = ["uuid": uuidSmartphone, "uuidExt": "DVLGNSS2A001", "svId": sat.id!, "gnssId": 2, "source": "client", "numWords": 8, "version": sat.versione, "iTow": sat.iTow!, "timestamp": sat.timestamp, "manufacturer": sat.manufacturer!, "model": sat.model, "dwrd0": sat.dwrd![0], "dwrd1": sat.dwrd![1], "dwrd2": sat.dwrd![2], "dwrd3": sat.dwrd![3], "dwrd4": sat.dwrd![4], "dwrd5": sat.dwrd![5], "dwrd6": sat.dwrd![6], "dwrd7": sat.dwrd![7]] as [String : Any]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
       
        var request = URLRequest(url: URL(string: "yourserverurl")!)
        
        request.allHTTPHeaderFields = ["X-Parse-Application-Id": "appId", "X-Parse-REST-API-Key": "yourestapikey"]
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData
       
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async(execute: { // controllo problemi di network
                    self.alertStandard(titolo: "WARNING", testo: "Network connection error")
                })
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // controllo errore                print("il codice dovrebbe essere 200, ma è \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            
            DispatchQueue.main.async(execute: {
                if let jsonDictionary = NetworkService.parseJSONFromData(data as Data) {
                    //Carico l'oggetto con tutto il contenuto appena scaricato
                    //print(jsonDictionary)
                    
                    let dictionary = jsonDictionary["result"]
                    let satId: Int = dictionary!["svId"] as? Int ?? 0
                    let esitoValidazione: Bool = dictionary!["valid"] as! Bool
                    let osnmaStr = dictionary!["osnma"] as! String
                    let validTimeStamp = dictionary!["timestamp"] as? Int ?? 0
                    print(satId)
                    
                    if esitoValidazione {
                        print("validato")
                        
                        let gnssId = sat.gnssId!
                        let satId = sat.id!
                        
                        let actSat = satelliti.first(where: { $0.gnssId == gnssId && $0.id == satId })
                        if  actSat != nil {
                            //actSat?.updateSFRBXData(sat: sat)
                            actSat!.validate(state: true)
                            actSat!.check(state: 1)
                            actSat!.setOsnma(osnma: osnmaStr)
                            actSat!.setValidTimeStamp(timestamp: validTimeStamp)
                        } else {
                            satelliti.append(sat)
                        }
                        
                        
                    } else if esitoValidazione == false {

                        let gnssId = sat.gnssId!
                        let satId = sat.id!
                        
                        let actSat = satelliti.first(where: { $0.gnssId == gnssId && $0.id == satId })
                        if  actSat != nil {
            
                        } else {
                            satelliti.append(sat)
                        }
                        
                    }
                    
                }
            })
            

        }
        task.resume()
    }
    
    func getNavPvt(characteristic: CBCharacteristic) {
        if (myPeripheal != nil) {
            
            if characteristic.value != nil {
                       
                let str = String(decoding: characteristic.value!, as: UTF8.self)
                let data = Data(str.utf8)
                

                do {
                    // make sure this JSON is in the format we expect
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        // try to read out a string array

                        navPVTData = json
                        
                    }
                                
                } catch let error as NSError {

                   
                }
                
                
            }
            
        }
    }
    
    override func viewDidLoad() {
        
        let bounds = CGRect(x: 0, y: 0, width: animView.frame.width, height: animView.frame.height)
        
       
        
        animationView.frame = CGRect(x: 0, y: 0, width: self.view.layer.frame.width, height: self.view.layer.frame.height)
           
        //animationView.center = self.container.center
        animationView.contentMode = .scaleAspectFill
                      
                                    
        animView.insertSubview(animationView, at: 0)
        
        animationView.play(fromProgress: 0, toProgress: 1, loopMode: .loop, completion: nil)
       
        
        
        manager = CBCentralManager(delegate: self, queue: nil)
        
        
        
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        manageObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        userView.layer.cornerRadius = 10
        /*userTitleView.layer.cornerRadius = 10
        userTitleView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        userView.layer.shadowColor = UIColor.black.cgColor
        userView.layer.shadowOffset = CGSize(width: 3, height: 3)
        userView.layer.shadowOpacity = 0.3
        userView.layer.shadowRadius = 2.0*/
        
        basicInfoView.layer.cornerRadius = 10
        /*basicInfoTitleView.layer.cornerRadius = 10
        basicInfoTitleView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        basicInfoView.layer.shadowColor = UIColor.black.cgColor
        basicInfoView.layer.shadowOffset = CGSize(width: 3, height: 3)
        basicInfoView.layer.shadowOpacity = 0.3
        basicInfoView.layer.shadowRadius = 2.0*/
        
        /*buttonView.layer.cornerRadius = 10
        buttonView.layer.shadowColor = UIColor.black.cgColor
        buttonView.layer.shadowOffset = CGSize(width: 3, height: 3)
        buttonView.layer.shadowOpacity = 0.3
        buttonView.layer.shadowRadius = 2.0*/
        
        locationManager.requestWhenInUseAuthorization()
        
        //updateLoggedUser()
        //updateBasicInfo()
        
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(updateBasicInfo), userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
        
        updateLoggedUser()
        updateBasicInfo()
        
        let extGPS = localStorage.bool(forKey: "externalGPS")
        let perUUID = localStorage.string(forKey: "periphealUUID")
        
        if extGPS {
            periphealUUID = CBUUID(string: perUUID ?? "00000000-0000-0000-0000-000000000000")
            if !timerNavPvt.isValid {
                self.timerNavPvt = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
                    self.triggerPvt()
                })
            }
            
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.all)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkLoggedUser()
        print(self.navigationController?.viewControllers.count)
        if (self.navigationController?.viewControllers.count)! > 1 {
            self.navigationController?.viewControllers.remove(at: 1)
        }
        
    }
    
   
    
    @IBAction func unwindToMainView(sender: UIStoryboardSegue) {
        updateLoggedUser()
        print("unwind")
    }

    @IBAction func photosButton(_ sender: UIButton) {
        performSegue(withIdentifier: "ShowPhotos", sender: self)
    }
    
    @IBAction func tasksButton(_ sender: UIButton) {
        performSegue(withIdentifier: "ShowTasks", sender: self)
    }
    
    @IBAction func mapButton(_ sender: UIButton) {
        performSegue(withIdentifier: "ShowMap", sender: self)
    }
    
    
    @IBAction func skyMapButton(_ sender: UIButton) {
        performSegue(withIdentifier: "ShowSkyMap", sender: self)
    }
    
    @IBAction func settingsButton(_ sender: UIButton) {
        performSegue(withIdentifier: "ShowSettings", sender: self)
    }
    @IBAction func aboutButton(_ sender: UIButton) {
        performSegue(withIdentifier: "ShowAbout", sender: self)
    }
        
    @IBAction func logout(_ sender: UIBarButtonItem) {
        UserStorage.removeObject(key: UserStorage.Key.userID)
        UserStorage.removeObject(key: UserStorage.Key.login)
        UserStorage.removeObject(key: UserStorage.Key.userName)
        UserStorage.removeObject(key: UserStorage.Key.userSurname)
        
        //updateLoggedUser()
        
        checkLoggedUser()
    }    
    
    private func checkLoggedUser() {
        let isLogged = UserStorage.exists(key: UserStorage.Key.userID)
        
        if isLogged != true {
            performSegue(withIdentifier: "ShowLoginScreen", sender: self)
        }
    }
    
    func updateLoggedUser() {
        if UserStorage.exists(key: UserStorage.Key.userID) == true {
            loginLabel.text = UserStorage.login
            nameLabel.text = getOpenTasksCount().description
            surnameLabel.text = getPhotoCount().description
        } else {
            loginLabel.text = ""
            nameLabel.text = ""
            surnameLabel.text = ""
        }        
    }
    
    private func getOpenTasksCount() -> Int {
        var tasks = [PersistTask]()
        
        let persistTasksRequest: NSFetchRequest<PersistTask> = PersistTask.fetchRequest()
        persistTasksRequest.predicate = NSPredicate(format: "userid == %@ AND status = 'open'", String(UserStorage.userID))
        do {
            tasks = try manageObjectContext.fetch(persistTasksRequest)
        }
        catch {
            print("Could not load save data: \(error.localizedDescription)")
        }
        
        return tasks.count
    }
    
    private func getPhotoCount() -> Int {
        var persistPhotos = [PersistPhoto]()
        
        let persistPhotoRequest: NSFetchRequest<PersistPhoto> = PersistPhoto.fetchRequest()
        persistPhotoRequest.predicate = NSPredicate(format: "userid == %@", String(UserStorage.userID))
        do {
            persistPhotos = try manageObjectContext.fetch(persistPhotoRequest)
        }
        catch {
            print("Could not load save data: \(error.localizedDescription)")
        }
        
        return persistPhotos.count
    }
    
    @objc func updateBasicInfo() {
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
                case .notDetermined, .restricted, .denied:
                    print("No access")
                    locationCheckImage.image = UIImage(named: "red_circle")
                case .authorizedAlways, .authorizedWhenInUse:
                    print("Access")
                    locationCheckImage.image = UIImage(named: "green_circle")
                @unknown default:
                break
            }
        } else {
            print("Location services are not enabled")
            locationCheckImage.image = UIImage(named: "red_circle")
        }
        
        if (UserStorage.exists(key: UserStorage.Key.gpsCapable) != true) {
            var capableType: Bool
            if (UIDevice().model == "iPhone") {
                switch UIDevice().type {
                    case .iPhone4, .iPhone4S, .iPhone5, .iPhone5C, .iPhone5S, .iPhone6Plus, .iPhone6: capableType = false
                    default: capableType = true
                }
            } else if (UIDevice().model == "iPad") {
                switch UIDevice().type {
                    case .iPad2, .iPad3, .iPad4, .iPadMini, .iPadMini2, .iPadMini3, .iPadMini4, .iPadAir, .iPadAir2: capableType = false
                    default: capableType = true
                }
            } else {
                capableType = false
            }
            
            var positiveAltitude: Bool
            if (self.locationManager.location?.altitude ?? 0 > 0) {
                positiveAltitude = true
            } else {
                positiveAltitude = false
            }
            
            if (capableType && positiveAltitude) {
                UserStorage.gpsCapable = true
            }
        }
        
        if (UserStorage.exists(key: UserStorage.Key.gpsCapable) == true) {
            galileoCheckImage.image = UIImage(named: "green_circle")
        } else {
            galileoCheckImage.image = UIImage(named: "red_circle")
        }       
        
    }
    
}

extension MainViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
            
            
        }
        
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        //print(characteristic.debugDescription)
        
        //NO
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //print(characteristic.debugDescription)
        
        if characteristic == myCharacteristic {
            //print("update sfrbx")
            self.addSat(characteristic: characteristic)
        }
        
        if characteristic == navCharacteristic {
            //self.getNavSat(characteristic: characteristic)
        }
        
        if characteristic == pvtCharacteristic {
            self.getNavPvt(characteristic: characteristic)
        }
        
        if characteristic == telCharacteristic {
            //self.getTelemetry(characteristic: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        
       //NO
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print(characteristic.debugDescription)
    }
   
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        myCharacteristic = characteristics[0]
        telCharacteristic = characteristics[1]
        navCharacteristic = characteristics[2]
        pvtCharacteristic = characteristics[3]
        
        myPeripheal?.setNotifyValue(true, for: myCharacteristic!)
        myPeripheal?.setNotifyValue(true, for: telCharacteristic!)
        myPeripheal?.setNotifyValue(true, for: navCharacteristic!)
        myPeripheal?.setNotifyValue(true, for: pvtCharacteristic!)


    }
}




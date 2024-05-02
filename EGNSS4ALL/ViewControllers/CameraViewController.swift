//
//  CameraViewController.swift
//  EGNSS4CAP
//
// 
//

import UIKit
import AVFoundation
import CoreData
import CryptoKit
import CoreLocation
import CoreBluetooth

class CameraViewController: UIViewController,AVCapturePhotoCaptureDelegate {
    
    private enum MsgInfo {
        case takePhotoWait
    }
    
    private enum MsgWarning {
        case unsatisfactoryLocData
        case unsatisfactoryCentroid
    }
    
    private static let captureQuality: AVCaptureSession.Preset = .high
    private static let dataCheckIntervalMils = 1000
    private static let autoSnapshotIntervalMils = 5000
    
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var timerPvtImg = Timer()
    
    let localStorage = UserDefaults.standard
    
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var accuracyLabel: UILabel!
    @IBOutlet weak var azimuthLabel: UILabel!
    @IBOutlet weak var tiltLabel: UILabel!
    
    @IBOutlet weak var latCentroidLabel: UILabel!
    @IBOutlet weak var lngCentroidLabel: UILabel!
    @IBOutlet weak var samplesCentroidLabel: UILabel!
    @IBOutlet weak var centroidView: UIView!
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var warningLabel: UILabel!
    
    @IBOutlet weak var snapshotButton: UIButton!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var messageView: UIStackView!
    
    var isCameraRunning = false
    
    private var photoDataController: PhotoDataController = PhotoDataController()
    private var isDataCheking = false
    
    private var isTakingPhoto = false
    private var takingPhotoTimer: Timer!
    private var snapshotDate: Date!
    
    private var infoMessages:[MsgInfo: String] = [:]
    private var warningMessages:[MsgWarning: String] = [:]
    
    var taskid:Int64 = -1
    
    //var persistPhotos = [PersistPhoto]()
    var manageObjectContext: NSManagedObjectContext!
    
   

    @IBOutlet weak var previewView: UIView!
    
    func setExternalLocation() {
        self.latitudeLabel.text = String(navPVTData["lat"] as? Double ?? 0.000000) + "°N"
        self.longitudeLabel.text = String(navPVTData["lon"] as? Double ?? 0.000000) + "°E"
        self.altitudeLabel.text = String(navPVTData["msl"] as? Double ?? 0.0)
        self.accuracyLabel.text = String(navPVTData["accH"] as? Double ?? 0.0)
        print(satelliti.count)
    }
    
    
    
    override func viewDidLoad() {
        
        
        
        
        super.viewDidLoad()
        //manager = CBCentralManager(delegate: self, queue: nil)
        /*snapshotButton.layer.cornerRadius = 10
        snapshotButton.layer.shadowColor = UIColor.black.cgColor
        snapshotButton.layer.shadowOffset = CGSize(width: 3, height: 3)
        snapshotButton.layer.shadowOpacity = 0.3
        snapshotButton.layer.shadowRadius = 2.0*/
        
        infoView.layer.cornerRadius = 10
        /*infoView.layer.shadowColor = UIColor.black.cgColor
        infoView.layer.shadowOffset = CGSize(width: 3, height: 3)
        infoView.layer.shadowOpacity = 0.3
        infoView.layer.shadowRadius = 2.0*/
        
        centroidView.layer.cornerRadius = 10
        /*centroidView.layer.shadowColor = UIColor.black.cgColor
        centroidView.layer.shadowOffset = CGSize(width: 3, height: 3)
        centroidView.layer.shadowOpacity = 0.3
        centroidView.layer.shadowRadius = 2.0*/
        
        messageView.layer.cornerRadius = 5
        /*messageView.layer.shadowColor = UIColor.black.cgColor
        messageView.layer.shadowOffset = CGSize(width: 3, height: 3)
        messageView.layer.shadowOpacity = 0.3
        messageView.layer.shadowRadius = 2.0*/
        let extGPS = localStorage.bool(forKey: "externalGPS")
        let perUUID = localStorage.string(forKey: "periphealUUID")
        
        if extGPS {
            self.timerPvtImg = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
                self.setExternalLocation()
                
            })
        }
        
       
        photoDataController.locationReceiver = {location in
            
            if extGPS {
                
              
                
            } else {
                self.latitudeLabel.text = String(format: "%f", location.coordinate.latitude)
                self.longitudeLabel.text = String(format: "%f", location.coordinate.longitude)
                self.altitudeLabel.text = String(format: "%.0f", location.altitude)
                self.accuracyLabel.text = String(format: "%.2f", location.horizontalAccuracy)
            }
           
        }
        
        
        photoDataController.headingReceiver = {heading in
            self.azimuthLabel.text = String(format: "%.0f", self.photoDataController.computePhotoHeading() ?? "unknown")
        }
        photoDataController.motionReceiver = { attitude in
            let tilt = self.photoDataController.computeTilt()
            if (tilt == nil) {
                self.tiltLabel.text = "unknown"
            } else {
                self.tiltLabel.text = String(format: "%.0f", tilt!)
            }
        }
        if SEStorage.centroidActive {
            photoDataController.centroidReceiver = {count, lat, lng in
                self.latCentroidLabel.text = lat == nil ? String("---") : String(format: "%f", lat!)
                self.lngCentroidLabel.text = lng == nil ? String("---") : String(format: "%f", lng!)
                self.samplesCentroidLabel.text = "\(count) / \(SEStorage.centroidCount)"
            }
            photoDataController.turnOnCentroid(count: SEStorage.centroidCount)
            centroidView.isHidden = false
        } else {
            photoDataController.turnOffCentroid()
            centroidView.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = Self.captureQuality
        
        guard let backCamera = AVCaptureDevice.default(for: .video) else {
            print("Unable to access back camera!")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            stillImageOutput = AVCapturePhotoOutput()
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
        } catch let error {
            print("Error Unable to initialize back camera: \(error.localizedDescription)")
        }
        
        photoDataController.start()
        adjustPhotoDataController()
        startDataChecking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.timerPvtImg.invalidate()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            coordinator.animate(alongsideTransition: { _ in
                if self.isCameraRunning {
                    self.adjustVideoPreviewLayer()
                    self.adjustStillImageOutput()
                }
                self.adjustPhotoDataController()
            }, completion: { (context) in
                //self.setVideoPreviewLayer()
            })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.captureSession.stopRunning()
        self.stopDataCheking()
        self.photoDataController.stop()
        self.takingPhotoTimer?.invalidate()
        
    }
    
    private func didRotate(notification: Notification) {
        //adjustStillImageOutput()
    }
    
    /*func getNavPvt(characteristic: CBCharacteristic) {
        if (myPeripheal != nil) {
            
            if characteristic.value != nil {
                
                print(String(decoding: characteristic.value!, as: UTF8.self))
                print("dentro")
                
                let str = String(decoding: characteristic.value!, as: UTF8.self)
                let data = Data(str.utf8)
                
                //print(str)

                do {
                    // make sure this JSON is in the format we expect
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        // try to read out a string array
                        
                        
                        
                        navPVTData = json
                        
                        
                    }
                                
                } catch let error as NSError {
                    //print("qui")
                    //print("Failed to load: \(error.localizedDescription)")
                   
                }
                
                
            }
            
        }
    }
    */
    
    
    func recordFunc() {
        if (myPeripheal != nil && myCharacteristic != nil) {
           
            if myCharacteristic?.value != nil {
                //print(String(decoding: (myCharacteristic?.value)!, as: UTF8.self))
                
                
                let str = String(decoding: (myCharacteristic?.value)!, as: UTF8.self)
                let data = Data(str.utf8)
                
                

                do {
                    // make sure this JSON is in the format we expect
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        // try to read out a string array
                        //print(json)
                        let pkt = json["pkt"] as! Int
                        if pkt == 2 {
                            let accuracyH = json["accH"] as! Double
                            let accuracyV = json["accV"] as! Double
                            let latitude = json["lat"] as! Double
                            let longitude = json["lon"] as! Double
                            let msl = json["msl"] as! Double
                           
                            //self.save(accH: accuracyH, accV: accuracyV, msl: msl, longitude: longitude, latitude: latitude)
                            self.localStorage.set(accuracyH, forKey: "accuracy")
                            self.localStorage.set(latitude, forKey: "latitude")
                            self.localStorage.set(longitude, forKey: "longitude")
                            self.localStorage.set(msl, forKey: "msl")
                        }
                        
                        if pkt == 3 {
                            let siv = json["siv"] as! Double
                            self.localStorage.set(siv, forKey: "siv")
                        }
                        
                    }
                } catch let error as NSError {
                    print("qui")
                    print("Failed to load: \(error.localizedDescription)")
                }
                
                
            }
            
        }
        //checkSats()
        //setExternalLocation()
    }
    
    /*func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
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
            
            print("Bluetooth disattivato")
        case .poweredOn:
            let extGPS = localStorage.bool(forKey: "externalGPS")
            
            
            if extGPS {
                manager?.scanForPeripherals(withServices:[serviceUUID], options: nil)
            }
            
            print("Bluetooth attivo")
        case .unsupported:
           
            print("Bluetooth non è supportato")
        default:
            
            print("Stato sconosciuto")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([serviceUUID])
        print("Connesso a " +  peripheral.name!)
       
    
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnesso da " +  peripheral.name!)
        self.alertStandard(titolo: "WARNING", testo: "External GNSS Disconnected")
        myPeripheal = nil
        myCharacteristic = nil
    
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print(error!)
    }*/
    
    func setupLivePreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        previewView.layer.addSublayer(videoPreviewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            
            DispatchQueue.main.async {
                self.isCameraRunning = true
                self.adjustVideoPreviewLayer()
                self.adjustStillImageOutput()
            }
        }
    }
    
    private func adjustVideoPreviewLayer() {
        videoPreviewLayer.frame = previewView.bounds
        switch UIApplication.shared.windows.first?.windowScene?.interfaceOrientation {
        case .portrait:
            videoPreviewLayer.connection?.videoOrientation = .portrait
        case .portraitUpsideDown:
            // není podporováno
            videoPreviewLayer.connection?.videoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            videoPreviewLayer.connection?.videoOrientation = .landscapeLeft
        case .landscapeRight:
            videoPreviewLayer.connection?.videoOrientation = .landscapeRight
        default:
            print("Unknown UI orientation for setting videoPreviewLayer.")
        }
    
    }
    
    private func adjustStillImageOutput() {
        if let photoOutputConnection = stillImageOutput.connection(with: AVMediaType.video) {
            switch UIApplication.shared.windows.first?.windowScene?.interfaceOrientation {
            case .portrait:
                photoOutputConnection.videoOrientation = .portrait
            case .portraitUpsideDown:
                // není podporováno
                photoOutputConnection.videoOrientation = .portraitUpsideDown
            case .landscapeLeft:
                photoOutputConnection.videoOrientation = .landscapeLeft
            case .landscapeRight:
                photoOutputConnection.videoOrientation = .landscapeRight
            default:
                print("Unknown device orientation for setting stillImageOutput.")
            }
        }
    }
    
    private func adjustPhotoDataController() {
        photoDataController.setOrientation(orientation: UIApplication.shared.windows.first?.windowScene?.interfaceOrientation)
    }
    
    @IBAction func startTakingPhoto(_ sender: UIButton) {
        if (!photoDataController.isAllDataCorrect() || isTakingPhoto) {
            return
        }
        if (takingPhotoTimer != nil) {
            takingPhotoTimer.invalidate()
        }
        setTakingPhotoState(start: true)
        snapshotDate = Date().addingTimeInterval(Double(Self.autoSnapshotIntervalMils) / 1000)
        takingPhotoTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(takingPhoto), userInfo: nil, repeats: true)
        takingPhotoTimer.fire()
    }
    
    private func takePhoto() {
        let settings = AVCapturePhotoSettings(format:[AVVideoCodecKey: AVVideoCodecType.jpeg])
        stillImageOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func takingPhoto() {
        let remain = snapshotDate.timeIntervalSince(Date())
        if (remain > 0) {
            addInfoMsg(type: .takePhotoWait, message: "Waiting to take snapshot.\nCalculating position.\n\(String(format: "%.0f", remain)) s")
        } else {
            removeInfoMsg(type: .takePhotoWait)
            takingPhotoTimer.invalidate()
            photoDataController.stop()
            if (photoDataController.isAllDataCorrect()) {
                takePhoto()
            } else {
                setTakingPhotoState(start: false)
                let alert = UIAlertController(title: "Photo Rejected", message: "The photo was rejected due to unsatisfactory location data.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Click", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer {
            setTakingPhotoState(start: false)
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        
        let image = UIImage(data: imageData)
        print("Size of captured image: " + image!.size.debugDescription)
        print("Image orientation: \(image!.imageOrientation.rawValue)")
                
        let userID = String(UserStorage.userID)
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let persistPhoto = PersistPhoto(context: manageObjectContext)
        
        persistPhoto.userid = Int64(userID) ?? 0
        
        persistPhoto.taskid = taskid
        
        let extGPS = localStorage.bool(forKey: "externalGPS")
        
        
        if extGPS {
           
            if let location = photoDataController.getLastLocation() {
                persistPhoto.lat = navPVTData["lat"] as? Double ?? 0.000000
                persistPhoto.lng = navPVTData["lon"] as? Double ?? 0.000000
                persistPhoto.altitude = navPVTData["msl"] as? Double ?? 0.0
                persistPhoto.bearing = location.course
                persistPhoto.accuracy = navPVTData["accH"] as? Double ?? 0.0
                var numValidSats: Int = 0
                if satelliti.count != 0 {
                    for i in 0...satelliti.count - 1 {
                        if satelliti[i].stato! {
                            numValidSats += 1
                        }
                    }
                }
                print(numValidSats)
                if numValidSats >= 3 {
                    persistPhoto.validated = true
                } else {
                    persistPhoto.validated = false
                }
                
            }
        } else {
            if let location = photoDataController.getLastLocation() {
                persistPhoto.lat = location.coordinate.latitude
                persistPhoto.lng = location.coordinate.longitude
                persistPhoto.altitude = location.altitude
                persistPhoto.bearing = location.course
                persistPhoto.accuracy = location.horizontalAccuracy
                persistPhoto.validated = false
            }
        }
        
        if let azim = photoDataController.getLastHeading() {
            persistPhoto.azimuth = azim.magneticHeading
            persistPhoto.photoHeading = photoDataController.computePhotoHeading() ?? azim.magneticHeading
        }
        if let orientation = photoDataController.getOrientation() {
            persistPhoto.orientation = Int64(Util.screenOrientationToExif(screenOrientation: orientation))
        }
        if let attitude = photoDataController.getLastAttitude() {
            persistPhoto.pitch = attitude.pitch
            persistPhoto.roll = attitude.roll
            persistPhoto.tilt = photoDataController.computeTilt()!
        }
        if SEStorage.centroidActive, let centroid = photoDataController.getLastCentroid() {
            persistPhoto.centroidLat = centroid.x
            persistPhoto.centroidLng = centroid.y
        }
        persistPhoto.created = Date()
        persistPhoto.sended = false
        persistPhoto.note = ""
        persistPhoto.photo = image!.jpegData(compressionQuality: 1)
        
        
        let stringDate = df.string(from: persistPhoto.created!)
        let photo_hash_string = SHA256.hash(data: persistPhoto.photo!).hexStr.lowercased()
        let digest_string1 = "bfb576892e43b763731a1596c428987893b2e76ce1be10f733_" + photo_hash_string + "_" + stringDate + "_" + userID
        persistPhoto.digest = SHA256.hash(data: digest_string1.data(using: .utf8)!).hexStr.lowercased()
        
        //persistPhotos += [persistPhoto]
               
        do{
            try self.manageObjectContext.save()
        }catch{
            print("Could not save data: \(error.localizedDescription)")
        }
        if taskid == -1 {
            performSegue(withIdentifier: "unwindToTableView", sender: self)
        } else {
            performSegue(withIdentifier: "unwindToTaskView", sender: self)
        }
    }
    
    private func setTakingPhotoState(start: Bool) {
        if (start) {
            isTakingPhoto = true
            photoDataController.restart()
            photoDataController.isSoftCorrection = false
        } else {
            photoDataController.start()
            isTakingPhoto = false
        }
    }
    
    // MARK: - Data Checking
    
    private func dataChecking() {
        DispatchQueue(label: "dataCheckingDQ").asyncAfter(deadline: .now() + .milliseconds(Self.dataCheckIntervalMils), execute: {
            DispatchQueue.main.async {
                if self.photoDataController.isDataLocationCorrect() {
                    self.removeWarningMsg(type: .unsatisfactoryLocData)
                } else {
                    self.addWarningMsg(type: .unsatisfactoryLocData, message: "Unsatisfactory location data.\nStay in place.")
                }
                
                if self.photoDataController.isCentroidCorrect() {
                    self.removeWarningMsg(type: .unsatisfactoryCentroid)
                } else {
                    self.addWarningMsg(type: .unsatisfactoryCentroid, message: "No centroid location.\nStay in place to collect all samples.")
                }
                
                if (self.isDataCheking) {
                    self.dataChecking()
                }
            }
        })
    }
    
    private func startDataChecking() {
        isDataCheking = true
        dataChecking()
    }
    
    private func stopDataCheking() {
        isDataCheking = false
    }
    
    // MARK: - Messages
    
    private func addInfoMsg(type: MsgInfo, message: String) {
        infoMessages[type] = message
        redrawInfoMsg()
    }
    
    private func addWarningMsg(type: MsgWarning, message: String) {
        warningMessages[type] = message
        redrawWarninMsg()
    }

    private func removeInfoMsg(type: MsgInfo) {
        infoMessages[type] = nil
        redrawInfoMsg()
    }
    
    private func removeWarningMsg(type: MsgWarning) {
        warningMessages[type] = nil
        redrawWarninMsg()
    }
    
    private func redrawInfoMsg() {
        redrawMsg(messages: infoMessages.map{$0.value}, label: infoLabel)
    }
    
    private func redrawWarninMsg() {
        redrawMsg(messages: warningMessages.map{$0.value}, label: warningLabel)
    }
    
    private func redrawMsg(messages: [String], label: UILabel) {
        var text = ""
        let pocet = messages.count;
        
        for i in 0..<pocet {
            text += messages[i]
            if (i < pocet-1) {
                text += "\n"
            }
        }
        label.text = text
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



/*extension CameraViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
            
            
        }
        
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print(characteristic.debugDescription)
        
        //NO
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //print(characteristic.debugDescription)
        
        if characteristic == myCharacteristic {
            //print("update sfrbx")
            //self.addSat(characteristic: characteristic)
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
}*/


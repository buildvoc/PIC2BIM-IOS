//
//  PhotoDetailViewController.swift
//  EGNSS4CAP
//
//  Created by FoxCom on 05/11/2020.
//

import UIKit
import CoreData
import MapKit

class PhotoDetailViewController: UIViewController {
    
    var persistPhoto: PersistPhoto!
    var manageObjectContext: NSManagedObjectContext!
    
    let localStorage = UserDefaults.standard
    var imageMap = UIImageView()

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var sendButton: UIBarButtonItem!
    @IBOutlet weak var metaView: UIView!
    @IBOutlet weak var latValueLabel: UILabel!
    @IBOutlet weak var lngValueLabel: UILabel!
    @IBOutlet weak var createdValueLabel: UILabel!
    @IBOutlet weak var sendedValueLabel: UILabel!
    @IBOutlet weak var noteValueLabel: UILabel!
    @IBOutlet weak var noteButton: UIBarButtonItem!
    @IBOutlet weak var pdfButton: UIButton!
    
    
    
    @IBAction func pdfAction(_ sender: UIButton) {
        guard
          let image = photoImageView.image
          else {
            // 2
            let alert = UIAlertController(title: "All Information Not Provided", message: "You must supply all information to create a PDF", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        let df = MyDateFormatter.yyyyMMdd
        
        guard let map = imageMap.image else { return }
        
        let pdfCreator = PDFCreator(title: "", image: image, map: map, latitude: persistPhoto.lat, longitude: persistPhoto.lng, shotDate: df.string(from: persistPhoto.created!), note: persistPhoto.note ?? "", send: persistPhoto.sended, validated: persistPhoto.validated)
        let pdfData = pdfCreator.createPDF()
        
        let vc = UIActivityViewController(activityItems: [pdfData], applicationActivities: [])
       
        // Oppure
        vc.popoverPresentationController?.sourceView = pdfButton // Specifica l'elemento di barra
        self.present(vc, animated: true, completion: nil)
        
    }
    
    @IBAction func send(_ sender: UIBarButtonItem) {
        let waitAlert = UIAlertController(title: nil, message: "Sending, please wait...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating();
        waitAlert.view.addSubview(loadingIndicator)
        
        self.present(waitAlert, animated: true, completion: nil)
        let userID = String(UserStorage.userID)
        
        struct Photo:Codable {
            var lat:Double
            var lng:Double
            var altitude:Double
            var bearing:Double
            var magnetic_azimuth:Double
            var photo_heading:Double
            var accuracy:Double
            var orientation:Int64
            var pitch:Double
            var roll:Double
            var photo_angle:Double
            var created:String
            var note:String
            var photo:String
            var digest:String
            var deviceManufacture:String
            var deviceModel:String
            var devicePlatform:String
            var deviceVersion:String
        }
        
        let df = MyDateFormatter.yyyyMMdd

        let stringDate = df.string(from: persistPhoto.created!)
        
        let data:Data = persistPhoto.photo!
        let base64String:String = data.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue:0))
        
        
        let photo = Photo(lat:persistPhoto.lat, lng:persistPhoto.lng, altitude: persistPhoto.altitude, bearing: persistPhoto.bearing, magnetic_azimuth: persistPhoto.azimuth, photo_heading: persistPhoto.photoHeading, accuracy: persistPhoto.accuracy, orientation: persistPhoto.orientation, pitch: persistPhoto.pitch, roll: persistPhoto.roll, photo_angle: persistPhoto.tilt, created: stringDate, note: persistPhoto.note ?? "", photo: base64String, digest:persistPhoto.digest! ,deviceManufacture: deviceManufacturer ,deviceModel: deviceModel ,devicePlatform:devicePlatform, deviceVersion: deviceVersion)
        
        do {
            let jsonData = try JSONEncoder().encode(photo)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            
            // Prepare URL
            let urlStr = Configuration.baseURLString + ApiEndPoint.photo
            print("------------------------------------------")
            print(urlStr)
            print("------------------------------------------")
            let url = URL(string: urlStr)
            guard let requestUrl = url else { fatalError() }
            // Prepare URL Request Object
            var request = URLRequest(url: requestUrl)
            request.httpMethod = "POST"
            request.setValue("Bearer \(UserStorage.token!)", forHTTPHeaderField: "Authorization")
            print(request)
            // HTTP Request Parameters which will be sent in HTTP Request Body
            let postString = "user_id="+userID+"&photo="+jsonString
            // Set HTTP Request Body
            request.httpBody = postString.data(using: String.Encoding.utf8);
            // Perform HTTP Request
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                // Check for Error
                if error != nil {
                    DispatchQueue.main.async {
                        waitAlert.dismiss(animated: true) {
                            self.showConnError()
                        }
                    }
                    return
                }
                // Convert HTTP Response Data to a String
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        waitAlert.dismiss(animated: true) {
                            self.processResponseData(data: dataString)
                        }
                    }
                }
            }
            task.resume()
            
        } catch { print(error) }
    }
    
    @IBAction func editNote(_ sender: UIBarButtonItem) {
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Photo note", message: "", preferredStyle: .alert)

        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = self.persistPhoto.note
        }

        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            
            self.persistPhoto.note = textField?.text
            
            do {
                try self.manageObjectContext.save()
            } catch {
                print("Could not save data: \(error.localizedDescription)")
            }
            
            self.updateDetail()
        }))

        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func mapScreenShot(completion: @escaping (UIImage?) -> Void) {
   
        let mapView = MKMapView(frame: CGRect(x: 0, y: 0, width: 300, height: 245))
        
       
        let initialLocation = CLLocationCoordinate2D(latitude: persistPhoto.lat, longitude: persistPhoto.lng)
        
        
        let zoomDelta = 0.002
        let region = MKCoordinateRegion(center: initialLocation, span: MKCoordinateSpan(latitudeDelta: zoomDelta, longitudeDelta: zoomDelta))
        
        mapView.setRegion(region, animated: false)
        
     
        let options = MKMapSnapshotter.Options()
        
        
        options.size = mapView.bounds.size
        options.mapType = .standard
        options.showsBuildings = true
        options.region = region
      
        //options.region.span = MKCoordinateSpan(latitudeDelta: zoomDelta, longitudeDelta: zoomDelta)
        

        let snapshotter = MKMapSnapshotter(options: options)
        

        snapshotter.start { snapshot, error in
            if let snapshotImage = snapshot?.image {
                completion(snapshotImage)
            } else {
                completion(nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapScreenShot { image in
            if let mapImage = image {
               
                self.imageMap.image = mapImage
            } else {
                // Error
            }
        }

        // Do any additional setup after loading the view.
        metaView.layer.cornerRadius = 10
        pdfButton.layer.cornerRadius = 10
        
        updateDetail()
        updateSendBUtton()
        
        print(latitudeApp)
        print(longitudeApp)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.all)
    }
    
    func updateSendBUtton() {
        if persistPhoto.sended == true {
            sendButton.isEnabled = false
            noteButton.isEnabled = false
        } else {
            sendButton.isEnabled = true
            noteButton.isEnabled = true
        }
    }
    
    func updateDetail() {
        photoImageView.image = UIImage(data: persistPhoto.photo!)
        print(persistPhoto.lat)
        print(persistPhoto.lng)
        if persistPhoto.lat == 0{
            latValueLabel.text = latitudeApp
            lngValueLabel.text = longitudeApp
        }else{
                    latValueLabel.text = persistPhoto.lat.description
                    lngValueLabel.text =  persistPhoto.lng.description

        }
//        latValueLabel.text = latitudeApp || persistPhoto.lat.description
//        lngValueLabel.text = longitudeApp|| persistPhoto.lng.description
        /* DEBUGCOM
        latValueLabel.text = persistPhoto.centroidLat.description
        lngValueLabel.text = persistPhoto.centroidLng.description
        /**/*/
        
        let df = MyDateFormatter.yyyyMMdd
        
        createdValueLabel.text = df.string(from: persistPhoto.created!)
        
        if persistPhoto.sended == true {
            sendedValueLabel.text = "yes"
        } else {
            sendedValueLabel.text = "no"
        }
        
        noteValueLabel.text = persistPhoto.note
    }
    
    func showConnError() {
        let alert = UIAlertController(title: "Sending error", message: "Connection error", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showSendingError() {
        let alert = UIAlertController(title: "Sending error", message: "Could not send photo", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showSendingSuccess() {
        let alert = UIAlertController(title: "Sending succesfull", message: "Photo was succesfully sent.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func processResponseData(data:String) {
        //print("Response data string:\n \(data)")
        struct Answer: Decodable {
            var status: String
            var error_msg: String?
            var photo_id: Int?
        }

        let jsonData = data.data(using: .utf8)!
        let answer = try! JSONDecoder().decode(Answer.self, from: jsonData)
        
        if answer.status == "ok" {
            showSendingSuccess()
            persistPhoto.sended = true
            persistPhoto.id = "\(answer.photo_id ?? 0)"
            do {
                try self.manageObjectContext.save()
            } catch {
                print("Could not save data: \(error.localizedDescription)")
            }
            
            updateDetail()
            updateSendBUtton()
        } else {
            showSendingError()
        }
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

// Created for the GSA in 2020-2021. Project management: SpaceTec Partners, software development: www.foxcom.eu

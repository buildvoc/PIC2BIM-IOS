//
//  MapViewController.swift
//  EGNSS4CAP
//
//
//

import UIKit
import CoreData
import MapKit
import CoreBluetooth


class MapViewController: UIViewController, MKMapViewDelegate, PTManagerDelegate, CLLocationManagerDelegate {
    
    
    private static let ptManagerIdentifier = "MapViewController"
    
    var firstAppear = true
    
    let db = DB()
    var persistPhotos: [PersistPhoto]?
    
    var satellites = [Satellite]()
    
    var timer = Timer()
    
    let localStorage = UserDefaults.standard
    
    let locationManager = CLLocationManager()
        
    @IBOutlet weak var _mkMapView: MKMapView!
    var mkMapView: MKMapView {
        return _mkMapView
    }
    
    var photoAnnotations: [Weak<PhotoMKAnnotation>] = []
    var azimAnnotations: [Weak<AzimuthMKAnnotation>] = []
    
    var ptManager: PTManager!
    var shownPath: PTPath?
    var trackingMode = "continuous"
    
    
    var viewDidAppearComplation : (() -> Void)?
    
    @IBOutlet weak var actValidSats: UILabel!
    @IBOutlet weak var recordPathButton: UIButton!
    @IBOutlet weak var showPathsButton: UIButton!
    @IBOutlet weak var switchButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var convexButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    
    @IBOutlet weak var shownPathInfoView: UIView!
    @IBOutlet weak var shownPTINameLabel: UILabel!
    @IBOutlet weak var shownPTITitileLabel: UILabel!
    @IBOutlet weak var shownModeLabel: UILabel!
    @IBOutlet weak var actLatLabel: UILabel!
    @IBOutlet weak var actLonLabel: UILabel!
    @IBOutlet weak var actAccLabel: UILabel!
    @IBOutlet weak var actSivLabel: UILabel!
    @IBOutlet weak var actValidSatsLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mkMapView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        mkMapView.register(PhotoMKAnnotationView.self, forAnnotationViewWithReuseIdentifier: PhotoMKAnnotation.photoAnnotationIndetifier)
        mkMapView.register(AzimuthMKAnnotationView.self, forAnnotationViewWithReuseIdentifier: AzimuthMKAnnotation.azimuthAnnotationIndetifier)
        ptManager = PTManager.acquire(indetifier: Self.ptManagerIdentifier, ptManagerDelegate: self)
        mkMapView.delegate = self
        
        /*recordPathButton.layer.cornerRadius = 10
        recordPathButton.layer.shadowColor = UIColor.black.cgColor
        recordPathButton.layer.shadowOffset = CGSize(width: 3, height: 3)
        recordPathButton.layer.shadowOpacity = 0.3
        recordPathButton.layer.shadowRadius = 2.0*/
        
        /*showPathsButton.layer.cornerRadius = 10
        showPathsButton.layer.shadowColor = UIColor.black.cgColor
        showPathsButton.layer.shadowOffset = CGSize(width: 3, height: 3)
        showPathsButton.layer.shadowOpacity = 0.3
        showPathsButton.layer.shadowRadius = 2.0*/
        
        shownPathInfoView.layer.cornerRadius = 10
        /*shownPathInfoView.layer.shadowColor = UIColor.black.cgColor
        shownPathInfoView.layer.shadowOffset = CGSize(width: 3, height: 3)
        shownPathInfoView.layer.shadowOpacity = 0.3
        shownPathInfoView.layer.shadowRadius = 2.0*/
        
        
        
        
        loadPhotos()
        showPhotos()
        
        setPathTrackState(isTracking: ptManager.isTracking)
    }
    
    func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    }
    
    func setupUserLocation() {
        mkMapView.showsUserLocation = true
        let buttonItem = MKUserTrackingBarButtonItem(mapView: mkMapView)
        self.navigationItem.rightBarButtonItem = buttonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
        let extGSP = localStorage.bool(forKey: "externalGPS")
        let perUUID = localStorage.string(forKey: "periphealUUID")
        
        if extGSP {
            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
                self.setExternalLocation()
                
            })
            recordPathButton.isHidden = true
            periphealUUID = CBUUID(string: perUUID ?? "00000000-0000-0000-0000-000000000000")
        } else {
            recordPathButton.isHidden = false
            setupLocationManager()
            setupUserLocation()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.all)
        self.timer.invalidate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (viewDidAppearComplation != nil) {
            viewDidAppearComplation!()
            viewDidAppearComplation = nil
        }
        refreshShownPath()
        if shownPath == nil && firstAppear {
            //mkMapView.showAnnotations(photoAnnotations.filter{$0.val != nil}.map{$0.val!}, animated: true)
            showUserLocation()
        }
        
        firstAppear = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        
        
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("aggiorno")
        let lat = round(userLocation.coordinate.latitude * 10000000) / 10000000
        let lng = round(userLocation.coordinate.longitude * 10000000) / 10000000
        let acc = round((userLocation.location?.horizontalAccuracy ?? 0) * 10) / 10
        
        self.actLatLabel.text = lat.description
        self.actLonLabel.text = lng.description
        if (acc > 0) {
            self.actAccLabel.text = acc.description
        } else {
            self.actAccLabel.text = "---"
        }
        
        /*if (self.waitAlert != nil) {
            self.waitAlert.message = "haha"
        }*/
        
    }
    
    func setExternalLocation() {
        
        
        setMapPoint()
        
        
        let latitude = navPVTData["lat"] as? Double ?? 0.000000
        let longitude = navPVTData["lon"] as? Double ?? 0.000000
        let accuracyH = navPVTData["accH"] as? Double ?? 0.0
        let accuracyV = navPVTData["accV"] as? Double ?? 0.0
        let msl = navPVTData["msl"] as? Double ?? 0.0
        let siv = navPVTData["siv"] as? Int ?? 0
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        //let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))

        //self._mkMapView.setRegion(region, animated: true)
        self._mkMapView.setCenter(center, animated: false)
        
        self.actLatLabel.text = String(latitude)
        self.actLonLabel.text = String(longitude)
        self.actAccLabel.text = String(accuracyH)
        var numValidSats = 0
       
        if satelliti.count != 0 {
            for i in 0...satelliti.count - 1 {
                if satelliti[i].stato! {
                    numValidSats += 1
                }
            }
        }
        
        self.actValidSats.text = String(numValidSats)
        self.actSivLabel.text = String(siv)
    }
    
    private func loadPhotos() {
        persistPhotos = PersistPhoto.selectByActualUser(manageObjectContext: db.mainMOC)
    }
    
    private func showPhotos() {
        DispatchQueue.main.async(execute: {
            guard let persistPhotos = self.persistPhotos else {
                return
            }
            
            var i = 0
            for photo in persistPhotos {
                let photoAnnotation = PhotoMKAnnotation(parentViewController: self, persistPhoto: photo)
                self.mkMapView.addAnnotation(photoAnnotation)
                self.photoAnnotations.append(Weak(photoAnnotation))
                let azimAnnotation = AzimuthMKAnnotation(photo: photo)
                self.mkMapView.addAnnotation(azimAnnotation)
                self.azimAnnotations.append(Weak(azimAnnotation))
                i += 1
            }
        })
    }
    
    private func customAnnotationView(in mapView: MKMapView, for annotation: MKAnnotation) -> CustomAnnotationView {
        let identifier = "CustomAnnotationViewID"

        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? CustomAnnotationView {
            annotationView.annotation = annotation
            return annotationView
        } else {
            let customAnnotationView = CustomAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            customAnnotationView.canShowCallout = true
            
            return customAnnotationView
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        switch annotation {
        case is PhotoMKAnnotation:
            return mapView.dequeueReusableAnnotationView(withIdentifier: PhotoMKAnnotation.photoAnnotationIndetifier, for: annotation)
        case is AzimuthMKAnnotation:
            return mapView.dequeueReusableAnnotationView(withIdentifier: AzimuthMKAnnotation.azimuthAnnotationIndetifier, for: annotation)
        case is PTMKAnnotation:
            return ptManager.mapView(mapView, viewFor: annotation)
        default:
            let customAnnotationView = self.customAnnotationView(in: mapView, for: annotation)
            //customAnnotationView.number = arc4random_uniform(10)
            let btn = UIButton(type: .detailDisclosure)
            customAnnotationView.rightCalloutAccessoryView = btn
            return customAnnotationView
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        switch overlay {
        case is PTPolyline, is PTPolygon:
            return ptManager.mapView(mapView, rendererFor: overlay)
        default:
            return MKPolylineRenderer()
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        for ann in azimAnnotations {
            if ann.val == nil {
                continue
            }
            let annView = mapView.view(for: ann.val!)
            if annView != nil {
                UIView.animate(withDuration: 0.3, animations: {
                    annView!.transform = CGAffineTransform(rotationAngle: CGFloat(Util.deg2rad(degs: -self._mkMapView.camera.heading)))
                })
                
            }
        }
    }
    
    func PTSavePathError(error: Error) {
        let alert = UIAlertController(title: "Tracking Path Error", message: "An unexpected error occured during saving Path: \(error.localizedDescription)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func PTNoPointError() {
        let alert = UIAlertController(title: "Tracking Path Error", message: "The path will not be saved because it does not contain any points.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func recordToggle(_ sender: Any) {
        let willTrack = !ptManager.isTracking
        if willTrack {
            let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
            alert.addTextField { textField in
                textField.placeholder = "Type name of path"
            }
            alert.addAction(UIAlertAction(title: "START RECORDING", style: .destructive, handler: { _ in
                let textField = alert.textFields![0]
                let name = textField.text == nil || textField.text!.isEmpty ? "Untitled" : textField.text!
                self.ptManager.startTrack(pathName: name)
                self.setPathTrackState(isTracking: willTrack)
                //self.showUserLocation()
                self.mkMapView.setUserTrackingMode(.follow, animated: true)
                UIApplication.shared.isIdleTimerDisabled = true
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Are you sure you want to stop recording the path?", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "STOP RECORDING", style: .destructive, handler: { _ in
                self.setPathTrackState(isTracking: willTrack)
                self.showPath(ptPath: self.ptManager.stopTrack())
                UIApplication.shared.isIdleTimerDisabled = false
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func switchClick(_ sender: Any) {
        if (trackingMode == "continuous") {
            trackingMode = "vertex"
            self.setPathTrackState(isTracking: true)
            self.ptManager.pauseTrack()
        } else {
            trackingMode = "continuous"
            self.setPathTrackState(isTracking: true)
            self.ptManager.unpauseTrack()
        }
    }
    
    @IBAction func deleteClick(_ sender: Any) {
        if (self.ptManager.getPointsCount() > 0) {
            let alert = UIAlertController(title: "Delete last point?", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "DELETE", style: .destructive, handler: { _ in
                self.ptManager.deleteLastPoint()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "No point to delete", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func convexClick(_ sender: Any) {
        let centroidWaitAlert = UIAlertController(title: "Computing convex hull point", message: "0/" + SEStorage.centroidCount.description, preferredStyle: .alert)
        centroidWaitAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            centroidWaitAlert.dismiss(animated: true)
            self.ptManager.cancelCentroidcapture()
        }))
        
        self.present(centroidWaitAlert, animated: true, completion: nil)
        self.ptManager.startCentroidCapture(alert: centroidWaitAlert)
    }
    
    @IBAction func captureClick(_ sender: Any) {
        self.ptManager.manualPointCapture()
    }
    
    func setPathTrackState(isTracking: Bool) {
        if isTracking {
            recordPathButton.setTitle("STOP", for: .normal)
            //recordPathButton.setImage(UIImage(named: "stop"), for: .normal)
            showPathInfo(ptPath: self.ptManager.acquirePTPathMainThread(), isRecording: isTracking)
            showTrackingButtons(isRecording: true, mode: trackingMode)
        } else {
            recordPathButton.setTitle("RECORD", for: .normal)
            //recordPathButton.setImage(UIImage(named: "record"), for: .normal)
            showPathInfo(ptPath: nil, isRecording: isTracking)
            showTrackingButtons(isRecording: false, mode: trackingMode)
        }
    }
    
    func showPath(ptPath: PTPath?) {
        let isTracking = ptManager.isTracking
        if isTracking {
            let alert = UIAlertController(title: "Cannot Draw Path", message: "The path cannot be drawn if another one is currently beeing recorded.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: false, completion: nil)
            return
        }
        shownPath = ptPath
        showPathInfo(ptPath: ptPath, isRecording: isTracking)
        ptManager.drawPathPolygon(ptPath: ptPath)
    }
    
    func showPathInfo(ptPath: PTPath?, isRecording: Bool) {
        if (ptPath == nil) {
            shownPathInfoView.isHidden = true
            return
        }
        shownPathInfoView.isHidden = false
        shownPTINameLabel.text = "Name: " + (ptPath?.name ?? "")
        if (isRecording) {
            shownPTITitileLabel.text = "Recording Path"
            if (trackingMode == "continuous") {
                shownModeLabel.text = "Continuous mode"
            } else {
                shownModeLabel.text = "Vertex mode"
            }
        } else {
            shownPTITitileLabel.text = "Showing Path"
            shownModeLabel.text = ""
        }
    }
    
    func showTrackingButtons (isRecording: Bool, mode: String) {
        if (isRecording) {
            switchButton.isHidden = false
            if (mode == "vertex") {
                captureButton.isHidden = false
                convexButton.isHidden = false
                deleteButton.isHidden = false
                switchButton.setTitle("SWITCH TO CONTINUOUS MODE", for: .normal)
            } else {
                captureButton.isHidden = true
                convexButton.isHidden = true
                deleteButton.isHidden = true
                switchButton.setTitle("SWITCH TO VERTEX MODE", for: .normal)
            }
        } else {
            switchButton.isHidden = true
            captureButton.isHidden = true
            convexButton.isHidden = true
            deleteButton.isHidden = true
        }
    }
    
    func refreshShownPath() {
        guard let path = shownPath else {
            return
        }
        var exist: Bool
        do {
            exist = try db.mainMOC.existingObject(with: path.objectID) != nil
        } catch {
            exist = false
        }
        if !exist {
            showPath(ptPath: nil)
        }
        
    }
    
    func showUserLocation() {
        mkMapView.setCenter(mkMapView.userLocation.coordinate, animated: true)
        mkMapView.setRegion(MKCoordinateRegion(center: mkMapView.userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)), animated: true)
    }
    
    @IBAction func unwindToMapView(sender: UIStoryboardSegue) {
        guard let source = sender.source as? PathTrackTableViewController else {
            return
        }
        guard let path = source.selectedPath else {
            return
        }
        viewDidAppearComplation = {
            self.showPath(ptPath: path)
        }
    }
    
    @IBAction func moveToPathTap(_ sender: UITapGestureRecognizer) {
        if ptManager.isTracking {
            showUserLocation()
        } else if shownPath != nil{
            ptManager.moveToPolygon()
        }
    }
    
    @IBAction func mapType(_ sender: UISegmentedControl) {
        switch (sender.selectedSegmentIndex) {
                case 0:
                    _mkMapView.mapType = MKMapType.standard
                case 1:
                    _mkMapView.mapType = MKMapType.satellite
                default:
                    _mkMapView.mapType = MKMapType.hybrid
            }
    }
    
    func setMapPoint() {
        mkMapView.removeAnnotations(mkMapView.annotations.filter { $0 !== mkMapView.userLocation })
        
        let point = MKPointAnnotation()
        
        var latitude = 0.0
        var longitude = 0.0
        var accuracyH = 0.0
        var accuracyV = 0.0
        var msl = 0.0
        
        let extGPS = localStorage.bool(forKey: "externalGPS")
       
        
        if extGPS {
            
            latitude = navPVTData["lat"] as? Double ?? 0.000000
            longitude = navPVTData["lon"] as? Double ?? 0.000000
            accuracyH = navPVTData["accH"] as? Double ?? 0.0
            accuracyV = navPVTData["accV"] as? Double ?? 0.0
            msl = navPVTData["msl"] as? Double ?? 0.0
        } else {
            latitude = mkMapView.userLocation.location?.coordinate.latitude ?? 0.0
            longitude = mkMapView.userLocation.location?.coordinate.longitude ?? 0.0
            msl = mkMapView.userLocation.location?.altitude ?? 0.0
            accuracyH = mkMapView.userLocation.location?.horizontalAccuracy ?? 0.0
            accuracyV = mkMapView.userLocation.location?.verticalAccuracy ?? 0.0
        }

        
        point.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        point.title = "lat: \(latitude), lon: \(longitude)"
        point.subtitle = "accH: \(accuracyH), accV: \(accuracyV), msl: \(msl)"
        self.mkMapView.addAnnotation(point)
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



class CustomAnnotationView: MKAnnotationView {
    private let annotationFrame = CGRect(x: 0, y: 0, width: 40, height: 40)
    private let label: UILabel

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        self.label = UILabel(frame: annotationFrame.offsetBy(dx: 0, dy: -6))
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.frame = annotationFrame
        self.label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        self.label.textColor = .white
        self.label.textAlignment = .center
        self.backgroundColor = .clear
        let pinImage = UIImage(named: "point")!
        self.image = pinImage
        //self.addSubview(pinImage)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented!")
    }

    public var number: UInt32 = 0 {
        didSet {
            //self.label.text = String(number)
        }
    }

    

}





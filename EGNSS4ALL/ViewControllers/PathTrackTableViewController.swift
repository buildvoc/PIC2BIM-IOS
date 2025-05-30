import UIKit
import CoreData

class PathTrackTableViewController: UITableViewController, UIDocumentPickerDelegate {
    
    let db = DB()
    var paths: [PTPath] = []
    var selectedPath: PTPath?
    let sendDQ = DispatchQueue(label: "sendDQ")
    let sendDB = DB()
    let c = DB().privateMOC
    let localStorage = UserDefaults.standard
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var sendButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        loadPaths()
    }
    
    func loadPaths() {
        paths = PTPath.selectByActualUser(manageObjectContext: db.mainMOC)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return paths.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let path = paths[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: PathTrackTableViewCell.indentifier, for: indexPath) as! PathTrackTableViewCell
        cell.nameLabel.text = path.name
        cell.startLabel.text = Util.prettyDate(date: path.start!) + " " + Util.prettyTime(date: path.start!)
        cell.endLabel.text = Util.prettyDate(date: path.end!) + " " + Util.prettyTime(date: path.end!)
        cell.areaLabel.text = path.area.description
        cell.sentLabel.text = path.sent ? "Yes" : "No"
        cell.selectionStyle = .none
        cell.kmlBtn.addTarget(self, action: #selector(kmlBtnTapped(_:)), for: .touchUpInside)
        cell.backgroundColor = .clear
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            db.mainMOC.delete(paths[indexPath.row])
            try! db.mainMOC.save()
            paths.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .top)
            break
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPath = paths[indexPath.row]
        performSegue(withIdentifier: "ShowPathInMap", sender: self)
    }
    
    @objc func kmlBtnTapped(_ sender: UIButton) {
        guard let indexPath = tableView.indexPath(for: sender.superview?.superview?.superview as! PathTrackTableViewCell) else {
            return
        }
        let selectedRow = indexPath.row
        selectedPath = paths[selectedRow]
        var groups = [DispatchGroup]()
        let dispatchGroup = DispatchGroup()
        groups.append(dispatchGroup)
        dispatchGroup.enter()
        if !self.genPathKML(ptPath: selectedPath!, dispatchGroup: dispatchGroup) {
            dispatchGroup.leave()
        }
    }
    
    @IBAction func editTable(_ sender: UIBarButtonItem) {
        if(tableView.isEditing == true) {
            tableView.isEditing = false
            editButton.title = "Edit"
            sendButton.isEnabled = true
        } else {
            tableView.isEditing = true
            editButton.title = "Done"
            sendButton.isEnabled = false
        }
    }
    
    @IBAction func sendAllAction(_ sender: UIBarButtonItem) {
        let pathsToSend = self.pathToSend(context: db.mainMOC)
        let toUpload = pathsToSend.count > 0
        var msg = "\(pathsToSend.count) Paths not uploaded."
        if (msg == "1 Paths not uploaded.") {
            msg = "1 Path not uploaded."
        }
        let snedAlert = UIAlertController(title: "Send All", message: msg, preferredStyle: .alert)
        snedAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: toUpload ? sendAll : nil))
        if toUpload {
            snedAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        }
        self.present(snedAlert, animated: true, completion: nil)
    }
    
    func sendAll(alert: UIAlertAction!) {
        let waitAlert = UIAlertController(title: nil, message: "Sending, please wait...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating();
        waitAlert.view.addSubview(loadingIndicator)
        sendDQ.async {
            DispatchQueue.main.sync {
                self.present(waitAlert, animated: true, completion: nil)
            }
            self.sendDB.privateMOC.reset()
            self.sendDB.privateMOC.retainsRegisteredObjects = true
            let pathsToSend = self.pathToSend(context: self.sendDB.privateMOC)
            var groups = [DispatchGroup]()
            for path in pathsToSend {
                let dispatchGroup = DispatchGroup()
                groups.append(dispatchGroup)
                dispatchGroup.enter()
                if !self.sendPath(ptPath: path, dispatchGroup: dispatchGroup) {
                    dispatchGroup.leave()
                }
            }
            for group in groups {
                group.wait()
            }
            
            DispatchQueue.main.sync {
                waitAlert.dismiss(animated: true) {
                    self.showSendAllResults()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func genPathKML(ptPath: PTPath, dispatchGroup: DispatchGroup) -> Bool {
        guard let ptPointsSet = ptPath.points else {
            return false
        }
        
        let ptPoints = ptPointsSet.array as! [PTPoint]
        
        let df = MyDateFormatter.yyyyMMdd
        struct RPoint: Codable {
            var lat: Double
            var lng: Double
            var created: String
        }
        var rPoints = [RPoint]()
        var coordinates:  [(latitude: Double, longitude: Double)] = []
        for p in ptPoints {
            coordinates.append((latitude: p.lat, longitude: p.lng))
            rPoints.append(RPoint(lat: p.lat, lng: p.lng, created: df.string(from: p.created!)))
        }
        let pointData: JSONEncoder.Output
        do {
            pointData = try JSONEncoder().encode(rPoints)
        } catch {
            print("Error encoding path to JSON: \(error.localizedDescription)" )
            return false
        }
        
        let jsonPointsString = String(data: pointData, encoding: .utf8)!
        print(jsonPointsString)
        
        
        
        
       // let polygon: [String: Any] = ["type": "Polygon", "coordinates": [coordinates]]
        
       // let feature: [String: Any] = ["type": "Feature", "geometry": polygon, "properties": [:]]
        
        
        print(coordinates)
        
        let kmlData = createKMLFromPolygon(coordinates: coordinates)
        
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            print("\(ptPath.name!).kml")
            let fileURL = url.appendingPathComponent("\(ptPath.name!).kml")
            do {
                try kmlData.write(to: fileURL)
                print("File salvato con successo in \(fileURL.path)")
                
//              let documentPicker = UIDocumentPickerViewController(url: fileURL, in: .exportToService) depricated code 
                let documentPicker = UIDocumentPickerViewController(forExporting: [fileURL])

                documentPicker.delegate = self
                present(documentPicker, animated: true)
            } catch {
                print("Errore durante il salvataggio del file: \(error.localizedDescription)")
            }
        }
        
        /*if let jsonData = try? JSONSerialization.data(withJSONObject: geojson, options: []) {
         if let jsonString = String(data: jsonData, encoding: .utf8) {
         
         
         
         
         if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
         print("\(ptPath.name!).geojson")
         let fileURL = url.appendingPathComponent("\(ptPath.name!).geojson")
         do {
         try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
         print("File salvato con successo in \(fileURL.path)")
         
         let documentPicker = UIDocumentPickerViewController(url: fileURL, in: .exportToService)
         documentPicker.delegate = self
         present(documentPicker, animated: true)
         } catch {
         print("Errore durante il salvataggio del file: \(error.localizedDescription)")
         }
         }
         }
         }*/
        
        
        
        return true
    }
    
    func createKMLFromPolygon(coordinates: [(latitude: Double, longitude: Double)]) -> Data {
        guard coordinates.count >= 3 else {
            fatalError("A polygon must have at least 3 coordinates.")
        }
        
        var kmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
        <Placemark>
        <Polygon>
        <outerBoundaryIs><LinearRing>
        <coordinates>
        """
        
        for coordinate in coordinates {
            kmlString += "\(coordinate.longitude),\(coordinate.latitude),0 "
        }
        
        kmlString += """
        </coordinates>
        </LinearRing></outerBoundaryIs>
        </Polygon>
        </Placemark>
        </Document>
        </kml>
        """
        
        return kmlString.data(using: .utf8) ?? Data()
    }
    
    
    func createKMLFromCoordinates(coordinates: [(latitude: Double, longitude: Double)]) -> String {
        var kmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
        """
        
        for (index, coordinate) in coordinates.enumerated() {
            let name = "Point \(index + 1)"
            let description = "Coordinate: \(coordinates[0]), \(coordinate.longitude)"
            
            kmlString += """
                <Placemark>
                    <name>\(name)</name>
                    <description>\(description)</description>
                    <Point>
                        <coordinates>\(coordinate.longitude),\(coordinate.latitude),0</coordinates>
                    </Point>
                </Placemark>
            """
        }
        
        kmlString += """
            </Document>
        </kml>
        """
        
        return kmlString
    }
    
    func sendPath(ptPath: PTPath, dispatchGroup: DispatchGroup) -> Bool {
        guard let ptPointsSet = ptPath.points else {
            return false
        }
        
        let ptPoints = ptPointsSet.array as! [PTPoint]
        
        let df = MyDateFormatter.yyyyMMdd
        
        struct RPoint: Codable {
            var lat: Double
            var lng: Double
            var created: String
            var altitude: Double
            var accuracy : Double
        }
        var rPoints = [RPoint]()
        for p in ptPoints {
            rPoints.append(RPoint(lat: p.lat, lng: p.lng, created: df.string(from: p.created!),altitude: p.altitude,accuracy: p.accuracy))
        }
        let pointData: JSONEncoder.Output
        do {
            pointData = try JSONEncoder().encode(rPoints)
        } catch {
            print("Error encoding path to JSON: \(error.localizedDescription)" )
            return false
        }
        
        let jsonPointsString = String(data: pointData, encoding: .utf8)!
        let params: [String: String] = [
            "user_id": String(UserStorage.userID),
            "name": ptPath.name!,
            "start": df.string(from: ptPath.start!),
            "end": df.string(from: ptPath.end!),
            "area": ptPath.area.description,
            "points": jsonPointsString
        ]
        
        // Prepare URL
        let urlStr = Configuration.baseURLString + ApiEndPoint.path
        print("------------------------------------------")
        print(urlStr)
        print("------------------------------------------")
        let url = URL(string: urlStr)
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
                            request.setValue("Bearer \(UserStorage.token!)", forHTTPHeaderField: "Authorization")

        let postString = Util.encodeParameters(params: params)
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("Error while sending path: \(error!.localizedDescription))")
            } else if let data = data, let dataString = String(data: data, encoding: .utf8) {
                self.sendDQ.async {
                    self.processResponse(ptPath: ptPath, data: dataString)
                }
            }
            dispatchGroup.leave()
        }
        task.resume()
        return true
    }
    
    func processResponse(ptPath: PTPath, data: String) {
        struct Answer: Decodable {
            var status: String
            var error_msg: String?
        }
        
        let jsonData = data.data(using: .utf8)!
        let answer: Answer
        do {
            answer = try JSONDecoder().decode(Answer.self, from: jsonData)
        } catch {
            print("Error during decoding server answer: \(error)")
            return
        }
        
        if answer.status == "ok" {
            ptPath.sent = true
        } else {
            print("Error response from server: \(answer.error_msg!)")
        }
        
        do {
            try self.sendDB.privateMOC.save()
        } catch {
            print("Error saving path send state: \(error)")
        }
    }
    
    func pathToSend(context: NSManagedObjectContext) -> [PTPath] {
        let paths = PTPath.selectByActualUser(manageObjectContext: context)
        return paths.filter{!$0.sent}
    }
    
    func showSendAllResults() {
        db.mainMOC.refreshAllObjects()
        let success = pathToSend(context: db.mainMOC).count == 0
        let title = success ? "Upload Successfull" : "Upload Failed"
        let msg = success ? "All paths were successfully uploaded." : "Not all routes were uploaded."
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func test_setSentState(isSent: Bool) {
        for path in paths {
            path.sent = isSent
        }
        try! db.mainMOC.save()
    }
    
}

// Created for the GSA in 2020-2021. Project management: SpaceTec Partners, software development: www.foxcom.eu

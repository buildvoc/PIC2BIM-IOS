//
//  PhotosTableViewController.swift
//  EGNSS4CAP
//
//  Created by FoxCom on 04/11/2020.
//

import UIKit
import CoreData
//import CryptoKit
//


class PhotosTableViewController: UITableViewController {
    
    var persistPhotos = [PersistPhoto]()
    var manageObjectContext: NSManagedObjectContext!
    
    var openDetail = false
    var scrollDown = false
    let localStorage = UserDefaults.standard
    var photoQueue: [String] = []
    let waitAlert = UIAlertController(title: nil, message: "Loading, please wait...", preferredStyle: .alert)
    let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 5, width: 50, height: 50))
    var emptyLabel = UILabel()
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var newButton: UIBarButtonItem!
    
    @IBAction func edit(_ sender: UIBarButtonItem) {
        if(tableView.isEditing == true)
        {
            tableView.isEditing = false
            editButton.title = "Edit"
            newButton.isEnabled = true
        }
        else
        {
            tableView.isEditing = true
            editButton.title = "Done"
            newButton.isEnabled = false
        }
    }
    
    @IBAction func newPhoto(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ShowCamera", sender: self)
    }
    
    @IBAction func unwindToTableView(sender: UIStoryboardSegue) {
        loadPersistPhotos()
        openDetail = true
    }
    
    func scrollToBottom() {
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.persistPhotos.count-1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupEmptyLabel()
        tableView.tableFooterView = UIView()
        manageObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
         /*
         if persistPhotos.count == 0 {
         loadSamplePhotos()
         }*/
    }
    
    override func viewWillAppear(_ animated:Bool) {
        loadPersistPhotos()
       // AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
        
        if openDetail == true {
            openDetail = false
            scrollDown = true
            performSegue(withIdentifier: "ShowPhotoDetailManual", sender: self)
        } else {
            tableView.reloadData()
            if scrollDown == true {
                scrollDown = false
                scrollToBottom()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.all)
    }
    
    
    @IBAction func syncTap(_ sender: Any) {
        getNewPhotos()
    }
    
    // MARK: - Table view data source
    
    func setupEmptyLabel(){
        let rect = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        let messageLabel = UILabel(frame: rect)
        messageLabel.text = "You don't have any photos yet.\n Tap to sync photos."
        messageLabel.textColor = UIColor.white
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center;
        messageLabel.font = .systemFont(ofSize: 15)
        messageLabel.sizeToFit()
        emptyLabel = messageLabel
        self.tableView.backgroundView = emptyLabel
        self.tableView.separatorStyle = .none
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if persistPhotos.count > 0 {
            emptyLabel.isHidden = true
            return 1
        } else {
            emptyLabel.isHidden = false
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return persistPhotos.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "PhotoTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? PhotoTableViewCell  else {
            return UITableViewCell()
        }
        
        let photo = persistPhotos[indexPath.row]
        
        cell.latValueLabel.text = photo.lat.description
        cell.lngValueLabel.text = photo.lng.description
        cell.backgroundColor = .clear
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = .clear
        
        let df = MyDateFormatter.yyyyMMdd
        
        cell.createdValueLabel.text = df.string(from: photo.created!)
        
        if photo.sended == true {
            cell.sendedValueLabel.text = "yes"
        } else {
            cell.sendedValueLabel.text = "no"
        }
        
        cell.noteValueLabel.text = photo.note
        
        cell.photoImage.image = UIImage(data: photo.photo!)
        
        return cell
    }
    
    
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            manageObjectContext.delete(persistPhotos[indexPath.row] as NSManagedObject)
            persistPhotos.remove(at: indexPath.row)
            if persistPhotos.isEmpty {
                tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
            } else {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            //tableView.deleteRows(at: [indexPath], with: .fade)
            
            do {
                try self.manageObjectContext.save()
            } catch {
                print("Could not save data: \(error.localizedDescription)")
            }
            
        }
//        else if editingStyle == .insert {
//            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//        }
    }
    
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "ShowCamera":
            guard let cameraViewController = segue.destination as? CameraViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            //cameraViewController.persistPhotos = persistPhotos
            cameraViewController.manageObjectContext = manageObjectContext
            
        case "ShowPhotoDetail":
            guard let photoDetailViewController = segue.destination as? PhotoDetailViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedPhotoCell = sender as? PhotoTableViewCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedPhotoCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedPhoto = persistPhotos[indexPath.row]
            photoDetailViewController.persistPhoto = selectedPhoto
            photoDetailViewController.manageObjectContext = manageObjectContext
            
        case "ShowPhotoDetailManual":
            guard let photoDetailViewController = segue.destination as? PhotoDetailViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            let selectedPhoto = persistPhotos[self.persistPhotos.count-1]
            photoDetailViewController.persistPhoto = selectedPhoto
            photoDetailViewController.manageObjectContext = manageObjectContext
            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    
    private func loadPersistPhotos() {
        let persistPhotoRequest: NSFetchRequest<PersistPhoto> = PersistPhoto.fetchRequest()
        persistPhotoRequest.predicate = NSPredicate(format: "userid == %@ AND taskid = -1", String(UserStorage.userID))
        do {
            persistPhotos = try manageObjectContext.fetch(persistPhotoRequest)
        }
        catch {
            print("Could not load save data: \(error.localizedDescription)")
        }
    }
    
//    private func loadSamplePhotos() {
//        let img1 = UIImage(named: "tree")
//        let img2 = UIImage(named: "tree")
//        
//        let userID = String(UserStorage.userID)
//        let df = MyDateFormatter.yyyyMMdd
//        
//        
//        let persistPhoto1 = PersistPhoto(context: manageObjectContext)
//        
//        persistPhoto1.userid = Int64(userID) ?? 0
//        persistPhoto1.lat = 1.0
//        persistPhoto1.lng = 1.1
//        persistPhoto1.created = Date()
//        persistPhoto1.sended = false
//        persistPhoto1.note = "pozn1"
//        persistPhoto1.photo = img1?.jpegData(compressionQuality: 1)
//        
//        let stringDate1 = df.string(from: persistPhoto1.created!)
//        let photo_hash_string1 = SHA256.hash(data: persistPhoto1.photo!).hexStr.lowercased()
//        let digest_string1 = "bfb576892e43b763731a1596c428987893b2e76ce1be10f733_" + photo_hash_string1 + "_" + stringDate1 + "_" + userID
//        persistPhoto1.digest = SHA256.hash(data: digest_string1.data(using: .utf8)!).hexStr.lowercased()
//        
//        let persistPhoto2 = PersistPhoto(context: manageObjectContext)
//        
//        persistPhoto2.userid = Int64(userID) ?? 0
//        persistPhoto2.lat = 2.0
//        persistPhoto2.lng = 2.1
//        persistPhoto2.created = Date()
//        persistPhoto2.sended = false
//        persistPhoto2.note = "pozn2"
//        persistPhoto2.photo = img2?.jpegData(compressionQuality: 1)
//        
//        let stringDate2 = df.string(from: persistPhoto2.created!)
//        let photo_hash_string2 = SHA256.hash(data: persistPhoto2.photo!).hexStr.lowercased()
//        let digest_string2 = "bfb576892e43b763731a1596c428987893b2e76ce1be10f733_" + photo_hash_string2 + "_" + stringDate2 + "_" + userID
//        persistPhoto2.digest = SHA256.hash(data: digest_string2.data(using: .utf8)!).hexStr.lowercased()
//        
//        persistPhotos += [persistPhoto1, persistPhoto2]
//        
//        do {
//            try self.manageObjectContext.save()
//        } catch {
//            print("Could not save data: \(error.localizedDescription)")
//        }
//        
//        print("Sample data loaded.")
//    }
    
}

// Created for the GSA in 2020-2021. Project management: SpaceTec Partners, software development: www.foxcom.eu


extension PhotosTableViewController {
    
    func getNewPhotos() {
        
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating();
        waitAlert.view.addSubview(loadingIndicator)
        
        self.present(waitAlert, animated: true, completion: nil)
        
        let userID = String(UserStorage.userID)
        
            // Prepare URL
            let urlStr = Configuration.baseURLString + ApiEndPoint.unassigned
            print("------------------------------------------")
            print(urlStr)
            print("------------------------------------------")
            
            let url = URL(string: urlStr)
            guard let requestUrl = url else { fatalError() }
            // Prepare URL Request Object
            var request = URLRequest(url: requestUrl)
            request.httpMethod = "POST"
                    request.setValue("Bearer \(UserStorage.token!)", forHTTPHeaderField: "Authorization")

            // HTTP Request Parameters which will be sent in HTTP Request Body
            let postString = "user_id="+userID
            // Set HTTP Request Body
            request.httpBody = postString.data(using: String.Encoding.utf8);
            // Perform HTTP Request
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                // Check for Error
                if error != nil {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                        
                        print("Loading tasks error 1.")
                        
                    }
                    return
                }
                // Convert HTTP Response Data to a String
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                        
                        print("Photos list loaded from server.")
                        print(dataString)
                        self.processResponseData(data: dataString)
                    }
                }
            }
            task.resume()
            
      
        
    }
    
    func downloadPhoto(idPhoto: String) {
        
        //let userID = String(UserStorage.userID)
        
            // Prepare URL
            let urlStr = Configuration.baseURLString + ApiEndPoint.getPhoto
            print("------------------------------------------")
            print(urlStr)
            print("------------------------------------------")
            
            let url = URL(string: urlStr)
            guard let requestUrl = url else { fatalError() }
            // Prepare URL Request Object
            var request = URLRequest(url: requestUrl)
            request.httpMethod = "POST"
                        // Set Authorization Header with Bearer Token
          request.setValue("Bearer \(UserStorage.token!)", forHTTPHeaderField: "Authorization")

            // HTTP Request Parameters which will be sent in HTTP Request Body
            let postString = "photo_id="+idPhoto
            // Set HTTP Request Body
            request.httpBody = postString.data(using: String.Encoding.utf8);
            // Perform HTTP Request
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                // Check for Error
                if error != nil {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                        
                        print("Loading tasks error 1.")
                        
                    }
                    return
                }
                // Convert HTTP Response Data to a String
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                        
                        print("Photo downloaded from server.")
                        print(dataString)
                        self.processResponsePhotoData(data: dataString, idPhoto: idPhoto)
                        if self.photoQueue.count == 0 {
                            self.waitAlert.dismiss(animated: true)
                        }
                        
                    }
                }
            }
            task.resume()
            
    
        
    }
    
    
    
    func processResponsePhotoData(data: String, idPhoto: String) {
               
        let jsonData = data.data(using: .utf8)!
        let answer = try! JSONDecoder().decode(GetPhotoResponse.self, from: jsonData)
        
        if answer.status == "ok" {
            
            
            let persistPhoto = PersistPhoto(context: manageObjectContext)
            let userID = String(UserStorage.userID)
            persistPhoto.userid = Int64(userID) ?? 0
            persistPhoto.id = idPhoto
            persistPhoto.note = answer.photo?.note
            persistPhoto.lat = Double(answer.photo?.lat ?? "0.0") ?? 0.0
            persistPhoto.lng = Double(answer.photo?.lng ?? "0.0") ?? 0.0
            persistPhoto.photoHeading = Double(answer.photo?.photo_heading ?? 0)
            persistPhoto.taskid = -1
            persistPhoto.digest = answer.photo?.digest
            
            let dateFormatter = MyDateFormatter.yyyyMMdd
            if let date = dateFormatter.date(from: answer.photo?.created ?? "") {
                persistPhoto.created = date
                
            } else {
                
                print("Error conversion date string")
            }
            
            if answer.photo?.osnma_validated == "1" {
                persistPhoto.validated = true
            } else {
                persistPhoto.validated = false
            }
            
            if let imageData = Data(base64Encoded: answer.photo?.photo ?? "") {
                persistPhoto.photo = imageData
            }
            
            persistPhoto.sended = true
            
            do{
                try self.manageObjectContext.save()
            } catch {
                print("Could not save data: \(error.localizedDescription)")
            }
            
            self.photoQueue = self.photoQueue.filter { $0 != idPhoto }
            
            loadPersistPhotos()
            tableView.reloadData()
            
        }
    }
    
    func processResponseData(data:String) {
        
        let jsonData = data.data(using: .utf8)!
        
        let answer = try! JSONDecoder().decode(Answer.self, from: jsonData)
        
        if answer.status == "ok" {
            struct Photo: Decodable {
                var photos_ids: [String]
                
            }
                        
            let jsonData = data.data(using: .utf8)!
            let answer = try! JSONDecoder().decode(Answer.self, from: jsonData)
            
            if answer.status == "ok" {
                let existingIds = Set(persistPhotos.map { $0.id })
                
                if !answer.photos_ids.isEmpty {
                    for i in 0...answer.photos_ids.count-1 {
                        if !existingIds.contains(String(answer.photos_ids[i])) {
                            print("L'id \(answer.photos_ids[i]) non esiste nel db")
                            self.photoQueue.append(String(answer.photos_ids[i])
                            )
                            //self.downloadPhoto(idPhoto: answer.photos_ids[i])
                            //answer.photos_ids.count-1
                            print(self.photoQueue)
                            if i == answer.photos_ids.count-1 {
                                for id in self.photoQueue {
                                    self.downloadPhoto(idPhoto: id)
                                }
                            }
                            // L'id non esiste, puoi aggiungere il nuovo oggetto all'array
                            //existingPersistPhotos.append(newPersistPhoto)
                        } else {
                            self.waitAlert.dismiss(animated: true)
                        }
                    }
                    print("status ok")
                }
                else
                {
                    self.waitAlert.dismiss(animated: true)

                }
                
            }
        }
    }
}

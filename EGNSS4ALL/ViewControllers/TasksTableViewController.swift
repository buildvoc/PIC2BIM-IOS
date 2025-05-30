//
//  TasksTableViewController.swift
//  GTPhotos
//
//  Created by FoxCom on 24.03.2021.
//

import UIKit
import CoreData
//import CryptoKit

class TasksTableViewController: UITableViewController {
    
    var persistTasks = [PersistTask]()
    var manageObjectContext: NSManagedObjectContext!
    
    let localStorage = UserDefaults.standard
    var emptyLabel = UILabel()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupEmptyLabel()
        manageObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated:Bool) {
        // AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
        loadPersistTasks()
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.all)
    }
    
    
    @IBAction func syncTap(_ sender: Any) {
        getNewTasks()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if persistTasks.count > 0 {
            emptyLabel.isHidden = true
            return 1
        } else {
            emptyLabel.isHidden = false
            return 0
        }
    }
    
    func setupEmptyLabel(){
        let rect = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        let messageLabel = UILabel(frame: rect)
        messageLabel.text = "You don't have any task yet.\n Tap to sync task."
        messageLabel.textColor = UIColor.white
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center;
        messageLabel.font = .systemFont(ofSize: 15)
        messageLabel.sizeToFit()
        emptyLabel = messageLabel
        self.tableView.backgroundView = emptyLabel
        self.tableView.separatorStyle = .none
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return persistTasks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "TaskTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TasksTableViewCell  else {
            return UITableViewCell()
            // fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        
        let task = persistTasks[indexPath.row]
        
        cell.nameLabel.text = task.name
        cell.statusLabel.text = task.status
        cell.backgroundColor = .clear
        
        if let dateCreated = task.date_created  {
            cell.createdLabel.text = MyDateFormatter.yyyyMMdd.string(from: dateCreated)
        }
        
        if let taskDueDate = task.task_due_date {
            cell.dueLabel.text = MyDateFormatter.yyyyMMdd.string(from: taskDueDate)
            if (taskDueDate < Date()) {
                cell.dueLabel.textColor = UIColor.systemRed
            } else {
                cell.dueLabel.textColor = UIColor.systemGreen
            }
        }
        
        if task.status == "data checked" {
         
            if(task.flag_invalid=="1")
            {
                cell.statusImage.image =   UIImage(named: "red_circle")
            }
            else
            {
                cell.statusImage.image =  UIImage(named: "green_circle")
            }
        }
        else if task.status == "new" {
            cell.statusImage.image = UIImage(named: "status_new")
        } else if task.status == "open"{
            cell.statusImage.image = UIImage(named: "status_open")
        } else if task.status == "returned"{
            cell.statusImage.image = UIImage(named: "status_returned")
        } else {
            cell.statusImage.image = UIImage(named: "status_provided")
        }
        
     /*  var persistPhotos = [PersistPhoto]()
        let persistPhotoRequest: NSFetchRequest<PersistPhoto> = PersistPhoto.fetchRequest()
        persistPhotoRequest.predicate = NSPredicate(format: "userid == %@ AND taskid == %i", String(UserStorage.userID), task.id)
        do {
            persistPhotos = try manageObjectContext.fetch(persistPhotoRequest)
        }
        catch {
            print("Could not load save data: \(error.localizedDescription)")
        }
        */
        
        //cell.countLabel.text = String(persistPhotos.count) + " photos"
        
        if let photoCount = task.photoCount {
            cell.countLabel.text = "\(photoCount) photos"
        } else {
            cell.countLabel.text = "0 photos"
        }
        if cell.countLabel.text == "1 photos" {
            cell.countLabel.text = "1 photo"
        }
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
            
        case "ShowTaskDetail":
            guard let taskViewController = segue.destination as? TaskViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedTaskCell = sender as? TasksTableViewCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedTaskCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedTask = persistTasks[indexPath.row]
            taskViewController.persistTask = selectedTask
            taskViewController.manageObjectContext = manageObjectContext
            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    
    // here
    private func loadPersistTasks() {
        let persistTaskRequest: NSFetchRequest<PersistTask> = PersistTask.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "date_created", ascending: false)
        let sortDescriptors = [sortDescriptor]
        persistTaskRequest.sortDescriptors = sortDescriptors
        persistTaskRequest.predicate = NSPredicate(format: "userid == %@", String(UserStorage.userID))
        do {
            persistTasks = try manageObjectContext.fetch(persistTaskRequest)
            print("Loaded \(persistTasks.count) tasks from Core Data.")
        }
        catch {
            print("Could not load save data: \(error.localizedDescription)")
        }
    }
    
    func getNewTasks() {
        let waitAlert = UIAlertController(title: nil, message: "Loading, please wait...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating();
        waitAlert.view.addSubview(loadingIndicator)
        
        self.present(waitAlert, animated: true, completion: nil)
        
        let userID = String(UserStorage.userID)
        
        let urlStr = Configuration.baseURLString + ApiEndPoint.tasks
        print("------------------------------------------")
        print(urlStr)
        print("------------------------------------------ ")
        

        let url = URL(string: urlStr)
        guard let requestUrl = url else { fatalError() }
        // Prepare URL Request Object
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
            // Set Authorization Header with Bearer Token
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
                    waitAlert.dismiss(animated: true) {
                        print("Loading tasks error 1.")
                    }
                }
                return
            }
            // Convert HTTP Response Data to a String
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("Tasks loaded from server.")
                print(dataString)
                self.processResponseData(data: dataString, completion: {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                        waitAlert.dismiss(animated: true) {
                        }
                    }
                })
            }
        }
        task.resume()
    }
    
    func processResponseData(data: String, completion: (() -> Void)?) {
        print("Response data string:\n \(data)")
        
        let jsonData = data.data(using: .utf8)!
        let answer = try! JSONDecoder().decode(TasksResponse.self, from: jsonData)
        
        if answer.status == "ok" {
            let dispatchGroup = DispatchGroup()
            
            let userID = String(UserStorage.userID)
            let df = MyDateFormatter.yyyyMMdd
            
            for task in answer.tasks ?? [] {
                if task.status == "new" || task.status == "data provided" || task.status == "data checked" || task.status == "open" {
                    let persistTaskRequest: NSFetchRequest<PersistTask> = PersistTask.fetchRequest()
                    persistTaskRequest.predicate = NSPredicate(format: "userid == %@ and id == %@ ", userID, String(task.id))
                    //Define way to modify data here
                    var perTasks = [PersistTask]()
                    do {
                        perTasks = try manageObjectContext.fetch(persistTaskRequest)
                        if let persistTask = perTasks.first {
                            if persistTask.flag_valid != task.flag_valid || persistTask.flag_invalid != task.flag_invalid || persistTask.status != task.status  {
                            persistTask.flag_valid = task.flag_valid
                            persistTask.flag_invalid = task.flag_invalid
                            persistTask.status = task.status
                            // Save the changes
                            try manageObjectContext.save()
                            print("Flags updated for task ID: \(task.id)")
                        }
                        }

                        
                        if perTasks.count == 0 {
                            print("inserting task")
                            let persistTask = PersistTask(context: manageObjectContext)
                            persistTask.userid = Int64(userID) ?? 0
                            persistTask.id = Int64(task.id)
                            persistTask.status = task.status
                            persistTask.flag_valid = task.flag_valid
                            persistTask.flag_invalid = task.flag_invalid
                            persistTask.name = task.name
                            persistTask.text = task.text
                            persistTask.photoCount = String(task.number_of_photos)
                            persistTask.text_returned = task.text_returned
                            persistTask.date_created = df.date(from: task.date_created)
                            persistTask.task_due_date = df.date(from: task.task_due_date)
                            
                            do {
                                try self.manageObjectContext.save()
                            } catch {
                                print("Could not save data: \(error.localizedDescription)")
                            }
                        }
                    }
                    catch {
                        print("Could not load save data: \(error.localizedDescription)")
                    }
                }
                
                if task.status == "returned" {
                    
                    let persistTaskRequest: NSFetchRequest<PersistTask> = PersistTask.fetchRequest()
                    persistTaskRequest.predicate = NSPredicate(format: "userid == %@ and id == %@ and status <> %@", userID, String(task.id), "returned")
                    
                    var perTasks = [PersistTask]()
                    do {
                        perTasks = try manageObjectContext.fetch(persistTaskRequest)
                        
                        if perTasks.count > 0 {
                            print("updating task")
                            let persistTask = perTasks[0]
                            
                            persistTask.text_returned = task.text_returned
                            persistTask.status = task.status
                            
                            do {
                                try self.manageObjectContext.save()
                            } catch {
                                print("Could not save data: \(error.localizedDescription)")
                            }
                        }
                    }
                    catch {
                        print("Could not load save data: \(error.localizedDescription)")
                    }
                }
                for photoID in task.photos_ids {
                    dispatchGroup.enter()
                    photoLoad(photoID: photoID, taskId: task.id, completion: {
                        dispatchGroup.leave()
                    })
                }
            }
            dispatchGroup.notify(queue: .main, execute: {
                completion?()
            })
        } else {
            completion?()
        }
        loadPersistTasks()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func photoLoad(photoID: Int?, taskId: Int, completion: (() -> Void)?) {
        guard let photoID = photoID else { return }
        
        let urlStr = Configuration.baseURLString + ApiEndPoint.getPhoto
        print("------------------------------------------")
        print(urlStr)
        print("------------------------------------------")
        let url = URL(string: urlStr)
        guard let requestUrl = url else { return }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
                    // Set Authorization Header with Bearer Token
        request.setValue("Bearer \(UserStorage.token!)", forHTTPHeaderField: "Authorization")

        let postString = "photo_id=" + String(photoID)
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error while loading photo: \(error.localizedDescription)")
                completion?()
                return
            }
            guard let data = data else {
                print("No data received for photo \(photoID)")
                completion?()
                return
            }
            
            let photoResponse = try? JSONDecoder().decode(GetPhotoResponse.self, from: data)
            guard let photo = photoResponse?.photo else {
                completion?()
                return
            }
            let userId = String(UserStorage.userID)
            
            let persistPhotoRequest: NSFetchRequest<PersistPhoto> = PersistPhoto.fetchRequest()
            persistPhotoRequest.predicate = NSPredicate(format: "userid == %@ AND taskid == %@ AND digest == %@ AND id == %@", String(UserStorage.userID), String(taskId), photo.digest,String(photoID))
            
            var persistPhoto = PersistPhoto(context: self.manageObjectContext)
            
            do {
                if let perPhoto = try self.manageObjectContext.fetch(persistPhotoRequest).first {
                    persistPhoto = perPhoto
                }
                
                persistPhoto.id = String(photoID)
                persistPhoto.userid = Int64(userId) ?? 0
                persistPhoto.taskid = Int64(taskId)
                persistPhoto.note = photo.note
                persistPhoto.lat = Double(photo.lat ?? "0.0") ?? 0
                persistPhoto.lng = Double(photo.lng ?? "0.0") ?? 0
                persistPhoto.photoHeading = Double(photo.photo_heading ?? 0)
                persistPhoto.digest = photo.digest
                persistPhoto.created = MyDateFormatter.yyyyMMdd.date(from: photo.created)
                if let base64Photo = photo.photo {
                    persistPhoto.photo = Data(base64Encoded: base64Photo)
                }
                
                try self.manageObjectContext.save()
            } catch {
                print("Could not save data: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                completion?()
            }
        }
        task.resume()
    }
    
    func displayPhoto(data: Data) {
        print("Photo data received: \(data)")
    }
}

// Created for the GSA in 2020-2021. Project management: SpaceTec Partners, software development: www.foxcom.eu

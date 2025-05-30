import UIKit
import CoreBluetooth



class SettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, alertPickerDelegate {
    func onCancel() {
        self.tableView.reloadData()
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var satellites = [Satellite]()
    private var alertController = UIAlertController()
    private var tblView = UITableView()
 
    
    let localStorage = UserDefaults.standard
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return SESection.allCases.count
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return SESection(rawValue: section) == nil ? 0 : SESection(rawValue: section)!.optionCount
        return 4
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row != 3 {
            let option = SEOption.init(rawValue: indexPath.row)!
            let cell = tableView.dequeueReusableCell(withIdentifier: option.type.reuseIdentifier, for: indexPath)
            let seCell = cell as! SECell
            seCell.reuse(option: option)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "activeGPS", for: indexPath) as! activeGPSCell
            
            cell.titolo = "External GNSS"
            let extGPS = localStorage.bool(forKey: "externalGPS")
            
            if extGPS {
                cell.activeSW.setOn(true, animated: false)
            } else {
                cell.activeSW.setOn(false, animated: false)
            }
            cell.activeSW.addTarget(self, action: #selector(self.enableExtGPS(_:)), for: .valueChanged)
            return cell
        }
        
    }
    
    
    @objc func enableExtGPS(_ sender : UISwitch!) {
        if sender.isOn {
            let sb = UIStoryboard(name: "Alerts", bundle: nil)
            let alertVC = sb.instantiateViewController(identifier: "alertPickerVC") as! alertPickerVC
            alertVC.modalPresentationStyle = .overCurrentContext
            alertVC.delegate = self
            alertVC.modalTransitionStyle = .crossDissolve
            self.present(alertVC, animated: true, completion: nil)
        } else {
            self.localStorage.set(false, forKey: "externalGPS")
            periphealUUID = CBUUID(string: "00000000-0000-0000-0000-000000000000")
            
            if (myPeripheal != nil) {
                manager?.cancelPeripheralConnection(myPeripheal!)
            }
            
        }
        
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
       
        self.tableView.reloadData()
    }
    
}


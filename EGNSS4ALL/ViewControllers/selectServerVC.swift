//
//  selectServerVC.swift
//  EGNSS4ALL
//
//  Created by Gabriele Amendola on 26/06/23.
//

import UIKit

class selectServerVC: UIViewController {

    @IBOutlet weak var serverEdit: UITextField!
    @IBOutlet weak var serverSW: UISwitch!
    
    let localStorage = UserDefaults.standard
    
    @IBAction func serverSWAct(_ sender: UISwitch) {
        if sender.isOn {
            localStorage.setValue(true, forKey: "customServer")
        } else {
            localStorage.setValue(false, forKey: "customServer")
        }
    }
    @IBAction func exitAction(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    @IBAction func saveAction(_ sender: UIButton) {
        
        if serverSW.isOn {
            let urlStr = serverEdit.text
            localStorage.setValue(true, forKey: "customServer")
            localStorage.setValue(urlStr, forKey: "url")
        } else {
            
            localStorage.setValue(false, forKey: "customServer")
            
        }
        
        
        self.dismiss(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let urlStr = localStorage.string(forKey: "url") ?? ""
        let customServer = localStorage.bool(forKey: "customServer")
        
        if customServer {
            serverSW.isOn = true
            serverEdit.text = urlStr
        } else {
            serverSW.isOn = false
            serverEdit.text = urlStr
            
        }
    }
    
    override func viewDidLoad() {
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

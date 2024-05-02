//
//  alertVC.swift
//  EGNSS4ALL
//
//  Created by ERASMICOIN on 18/03/22.
//

import UIKit

class alertVC: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var titoloLabel: UILabel!
    @IBOutlet weak var okButton: UIButton!
    
    
    @IBAction func okAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var titolo: String = ""
    var messaggio: String = ""
    var funzione: String = ""
    
    func updateUI() {
        okButton.btnSetup(label: "Ok", color: "primary")
        titoloLabel.text = titolo
        textLabel.text = messaggio
        containerView.layer.backgroundColor = UIColor(named: "background")?.cgColor
        containerView.layer.cornerRadius = 8
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 3)
        containerView.layer.shadowOpacity = 0.42
        containerView.layer.shadowRadius = 4
    }
    
    override func viewDidLoad() {
        
        updateUI()

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

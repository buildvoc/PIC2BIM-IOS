//
//  SkyViewVC.swift
//  EGNSS4CAP
//
//  Created by Gabriele Amendola on 30/05/22.
//

import UIKit
import CoreLocation


class SkyViewVC: UIViewController, CLLocationManagerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    
    @IBOutlet weak var circleView: CircleView!
    
    @IBOutlet weak var selectBtn: UIButton!
    @IBOutlet weak var constLabel: UILabel!
    
    @IBOutlet weak var pickerConst: UIPickerView!
    @IBOutlet weak var constBtn: UIButton!
    
    
    @IBAction func selectAction(_ sender: UIButton) {
        localStorage.set(pickerConst.selectedRow(inComponent: 0), forKey: "constellation")
        UIView.animate(withDuration: 0.2, delay: 0.1, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.circleView.alpha = 1.0
            self.pickerConst.alpha = 0.0
            self.selectBtn.alpha = 0.0
        }, completion: nil)
        
        constLabel.text = pickerData[localStorage.integer(forKey: "constellation")]
        let currentLoc = locationManager.location
        
        for subView in circleView.subviews{
            if let satsBtn = subView as? UIButton {
                satsBtn.removeFromSuperview()
            }
        }
 
        getSats(lat: currentLoc!.coordinate.latitude, lon: currentLoc!.coordinate.longitude, type: pickerData[localStorage.integer(forKey: "constellation")])
    }
    
    @IBAction func selectConst(_ sender: UIButton) {
        if circleView.alpha == 1 {
            UIView.animate(withDuration: 0.2, delay: 0.1, options: UIView.AnimationOptions.curveEaseOut, animations: {
                self.circleView.alpha = 0.0
                self.pickerConst.alpha = 1.0
                self.selectBtn.alpha = 1.0
            }, completion: nil)
            let row = localStorage.object(forKey: "constellation") as? Int ?? 0
            pickerConst.selectRow(row, inComponent: 0, animated: false)
        } else {
            UIView.animate(withDuration: 0.2, delay: 0.1, options: UIView.AnimationOptions.curveEaseOut, animations: {
                self.circleView.alpha = 1.0
                self.pickerConst.alpha = 0.0
                self.selectBtn.alpha = 0.0
            }, completion: nil)
            
        }
    }
    
    let locationManager = CLLocationManager()
    let localStorage = UserDefaults.standard
    
    var sats = [Satellite]()
    var pickerData: [String] = [String]()
    
    func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    }
    
    func drawSats() {
        
        for i in self.sats {
            let elevation = 90 - i.elev!
            let azimuth = i.azim!
            
            let x = Double(elevation)*sin(Double(azimuth) * Double.pi / 180)
            let y = Double(elevation)*cos(Double(azimuth) * Double.pi / 180)
            
            let satBtn = UIButton(type: .custom)
                   
            satBtn.frame = CGRect(x: 165 + x*1.72, y: 165 - y*1.72 , width: 24, height: 24)
            
            satBtn.setTitle(String(i.id ?? 0), for: .normal)
            satBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 11)
            
            satBtn.setBackgroundImage(UIImage(named: "status_open"), for: .normal)
            
            circleView.addSubview(satBtn)
        }
        
    }
    
    func getSats(lat: Double, lon: Double, type: String) {
       
        let json = ["lat": lat, "lon": lon, "type": type] as [String : Any]
        let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        var request = URLRequest(url: URL(string: "https://www.tlesatellite.com/getSatellites")!)
        
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // controllo problemi di network
                print("error=\(String(describing: error))")

                return
            }
          
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // controllo errore
                print("il codice dovrebbe essere 200, ma è \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            
           if let jsonDictionary = NetworkService.parseJSONFromData(data as Data) {
                 //Carico l'oggetto con tutto il contenuto appena scaricato
                print(jsonDictionary)
                DispatchQueue.main.async(execute: {
                    self.sats = Satellite.downloadAllSatsSkyView(datiJson: data as NSData)
                    
                    self.drawSats()
                })
            }
            //let responseString = String(data: data, encoding: .utf8)
            //print(responseString)
        }
        task.resume()
    }
    
    override func viewDidLoad() {
        
        pickerConst.alpha = 0
        selectBtn.alpha = 0
        self.pickerConst.delegate = self
        self.pickerConst.dataSource = self
        
        pickerData = ["GPS", "GLONASS", "BEIDOU", "GALILEO"]
        
        
        setupLocationManager()
        let currentLoc = locationManager.location
        
        constLabel.text = pickerData[localStorage.integer(forKey: "constellation")]
        
        if currentLoc != nil {
            getSats(lat: currentLoc!.coordinate.latitude, lon: currentLoc!.coordinate.longitude, type: pickerData[localStorage.integer(forKey: "constellation") ])
        } else {
            self.alertStandard(titolo: "WARNING", testo: "Activate location services")
        }
        
        
        
        
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

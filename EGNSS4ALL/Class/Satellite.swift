//
//  Satellite.swift
//  EGNSS4ALL
//
//  Created by ERASMICOIN on 06/06/22.
//

import Foundation

class Satellite
{
    var id: Int?
    var gnssId: Int?
    var timestamp: Int?
    var validTimeStamp: Int?
    var source: String?
    var numWords: Int?
    var versione: Int?
    var iTow: Double?
    var manufacturer: String?
    var model: String?
    var dwrd: Array<Any>?
    var stato: Bool?
    var checked: Int?
    var osnma: String?
    var azim: Int?
    var elev: Int?
    var cno: Int?
    var valid: Bool?
    
    
    
    func validate(state: Bool) {
        self.stato = state
    }
    
    func check(state: Int) {
        self.checked = state
    }
    
    func setOsnma(osnma: String) {
        self.osnma = osnma
    }
    
    func setValidTimeStamp(timestamp: Int) {
        self.validTimeStamp = timestamp
    }
    
    func updateNavData(satellite: Satellite) {
        self.azim = satellite.azim
        self.elev = satellite.elev
        self.cno = satellite.cno
    }
    
    func updateSFRBXData(sat: Satellite) {
        self.timestamp = sat.timestamp
        
        var dwrd = [Int]()
        
        let dwrd0 = sat.dwrd![0] as? Int ?? 0
        let dwrd1 = sat.dwrd![1] as? Int ?? 0
        let dwrd2 = sat.dwrd![2] as? Int ?? 0
        let dwrd3 = sat.dwrd![3] as? Int ?? 0
        let dwrd4 = sat.dwrd![4] as? Int ?? 0
        let dwrd5 = sat.dwrd![5] as? Int ?? 0
        let dwrd6 = sat.dwrd![6] as? Int ?? 0
        let dwrd7 = sat.dwrd![7] as? Int ?? 0
        
        dwrd.append(dwrd0)
        dwrd.append(dwrd1)
        dwrd.append(dwrd2)
        dwrd.append(dwrd3)
        dwrd.append(dwrd4)
        dwrd.append(dwrd5)
        dwrd.append(dwrd6)
        dwrd.append(dwrd7)
        
        self.dwrd = dwrd
        
        
        
        
    }
    
    
    
    init(id: Int, gnssId: Int, timestamp: Int, validTimeStamp: Int, source: String, numWords: Int, versione: Int, iTow: Double, manufacturer: String, model: String, dwrd: Array<Any>, stato: Bool, checked: Int, osnma: String, azim: Int, elev: Int, cno: Int, valid: Bool)
    {
        self.id = id
        self.gnssId = gnssId
        self.timestamp = timestamp
        self.validTimeStamp = validTimeStamp
        self.source = source
        self.numWords = numWords
        self.versione = versione
        self.iTow = iTow
        self.manufacturer = manufacturer
        self.model = model
        self.dwrd = dwrd
        self.stato = stato
        self.checked = checked
        self.osnma = osnma
        self.azim = azim
        self.elev = elev
        self.cno = cno
        self.valid = valid
    }
    
    typealias SatellitesDictionary = [String : AnyObject]
    
    init(dizionarioSat: SatellitesDictionary)
    {
        self.id = dizionarioSat["id"] as? Int
        self.gnssId = dizionarioSat["azimuth"] as? Int
        
    }
    
    enum gestoreErrori: Error {
        case FoundNil
    }
    
    
    
    static func downloadAllSats(jsonArray: [[String: Any]]) -> [Satellite]
    {
            
        var sats = [Satellite]()
        
        
        for i in 0...jsonArray.count - 1 {
            if jsonArray[i]["svId"] == nil {
                return []
            }
            let id = jsonArray[i]["svId"] as! Int
            
            let gnssId = jsonArray[i]["gnssId"] as! Int
            let timestamp = jsonArray[i]["timestamp"] as? Int ?? Int(Date().timeIntervalSince1970)
                let source = "client"
            let numWords = jsonArray[i]["numWords"] as? Int ?? 0
                let versione = jsonArray[i]["version"] as? Int ?? 0
            let iTow = jsonArray[i]["iTow"] as? Double ?? 0.0
                let manufacturer = jsonArray[i]["manufacturer"] as? String ?? ""
                let model = jsonArray[i]["model"] as? String ?? ""
                var dwrd = [Int]()
                
            let dwrd0 = jsonArray[i]["dwrd0"] as? Int ?? 0
                let dwrd1 = jsonArray[i]["dwrd1"] as? Int ?? 0
                let dwrd2 = jsonArray[i]["dwrd2"] as? Int ?? 0
                let dwrd3 = jsonArray[i]["dwrd3"] as? Int ?? 0
                let dwrd4 = jsonArray[i]["dwrd4"] as? Int ?? 0
                let dwrd5 = jsonArray[i]["dwrd5"] as? Int ?? 0
                let dwrd6 = jsonArray[i]["dwrd6"] as? Int ?? 0
                let dwrd7 = jsonArray[i]["dwrd7"] as? Int ?? 0
                
                dwrd.append(dwrd0)
                dwrd.append(dwrd1)
                dwrd.append(dwrd2)
                dwrd.append(dwrd3)
                dwrd.append(dwrd4)
                dwrd.append(dwrd5)
                dwrd.append(dwrd6)
                dwrd.append(dwrd7)
            
            let azim = jsonArray[i]["azim"] as! Int
            let elev = jsonArray[i]["elev"] as! Int
            let cno = jsonArray[i]["cno"] as! Int
                
            let sat = Satellite.init(id: id, gnssId: gnssId, timestamp: timestamp, validTimeStamp: 0, source: source, numWords: numWords, versione: versione, iTow: iTow, manufacturer: manufacturer, model: model, dwrd: dwrd, stato: false, checked: 0, osnma: "Validating...", azim: azim, elev: elev, cno: cno, valid: true)
            sats.append(sat)
        }
        
        
        
        return sats
    }
    
    static func downloadSingleSat(jsonArray: [String: Any]) -> Satellite
    {
            
            
        let id = jsonArray["svId"] as! Int
        let gnssId = jsonArray["gnssId"] as! Int
        let osnma = jsonArray["OSNMA"] as? String ?? "0000000000000000000000000000000000000000"
        let timestamp = jsonArray["timestamp"] as? Int ?? Int(Date().timeIntervalSince1970)
            let source = "client"
        let numWords = jsonArray["numWords"] as? Int ?? 0
            let versione = jsonArray["version"] as? Int ?? 0
        let iTow = jsonArray["iTow"] as? Double ?? 0.0
            let manufacturer = jsonArray["manufacturer"] as? String ?? ""
            let model = jsonArray["model"] as? String ?? ""
            var dwrd = [Int]()
            
        let dwrd0 = jsonArray["dwrd0"] as? Int ?? 0
            let dwrd1 = jsonArray["dwrd1"] as? Int ?? 0
            let dwrd2 = jsonArray["dwrd2"] as? Int ?? 0
            let dwrd3 = jsonArray["dwrd3"] as? Int ?? 0
            let dwrd4 = jsonArray["dwrd4"] as? Int ?? 0
            let dwrd5 = jsonArray["dwrd5"] as? Int ?? 0
            let dwrd6 = jsonArray["dwrd6"] as? Int ?? 0
            let dwrd7 = jsonArray["dwrd7"] as? Int ?? 0
            
            dwrd.append(dwrd0)
            dwrd.append(dwrd1)
            dwrd.append(dwrd2)
            dwrd.append(dwrd3)
            dwrd.append(dwrd4)
            dwrd.append(dwrd5)
            dwrd.append(dwrd6)
            dwrd.append(dwrd7)
        
        let azim = jsonArray["azim"] as? Int ?? 0
        let elev = jsonArray["elev"] as? Int ?? 0
        let cno = jsonArray["cno"] as? Int ?? 0
            
        let sat = Satellite.init(id: id, gnssId: gnssId, timestamp: timestamp, validTimeStamp: 0, source: source, numWords: numWords, versione: versione, iTow: iTow, manufacturer: manufacturer, model: model, dwrd: dwrd, stato: false, checked: 0, osnma: osnma, azim: azim, elev: elev, cno: cno, valid: true)
            
        
        return sat
    }
    
    static func downloadSingleSatLTE(jsonArray: [String: Any]) -> Satellite
    {
            
            
        let id = jsonArray["svId"] as! Int
        let gnssId = jsonArray["gnssId"] as! Int
        let osnma = jsonArray["osnma"] as? String ?? "0000000000000000000000000000000000000000"
        let timestamp = jsonArray["timestamp"] as? Int ?? Int(Date().timeIntervalSince1970)
            let source = "client"
        let numWords = jsonArray["numWords"] as? Int ?? 0
            let versione = jsonArray["version"] as? Int ?? 0
        let iTow = jsonArray["iTow"] as? Double ?? 0.0
            let manufacturer = jsonArray["manufacturer"] as? String ?? ""
            let model = jsonArray["model"] as? String ?? ""
            var dwrd = [Int]()
            
        let dwrd0 = jsonArray["dwrd0"] as? Int ?? 0
            let dwrd1 = jsonArray["dwrd1"] as? Int ?? 0
            let dwrd2 = jsonArray["dwrd2"] as? Int ?? 0
            let dwrd3 = jsonArray["dwrd3"] as? Int ?? 0
            let dwrd4 = jsonArray["dwrd4"] as? Int ?? 0
            let dwrd5 = jsonArray["dwrd5"] as? Int ?? 0
            let dwrd6 = jsonArray["dwrd6"] as? Int ?? 0
            let dwrd7 = jsonArray["dwrd7"] as? Int ?? 0
            
            dwrd.append(dwrd0)
            dwrd.append(dwrd1)
            dwrd.append(dwrd2)
            dwrd.append(dwrd3)
            dwrd.append(dwrd4)
            dwrd.append(dwrd5)
            dwrd.append(dwrd6)
            dwrd.append(dwrd7)
        
        let azim = jsonArray["azim"] as? Int ?? 0
        let elev = jsonArray["elev"] as? Int ?? 0
        let cno = jsonArray["cno"] as? Int ?? 0
            
        let sat = Satellite.init(id: id, gnssId: gnssId, timestamp: timestamp, validTimeStamp: 0, source: source, numWords: numWords, versione: versione, iTow: iTow, manufacturer: manufacturer, model: model, dwrd: dwrd, stato: false, checked: 0, osnma: osnma, azim: azim, elev: elev, cno: cno, valid: true)
            
        
        return sat
    }
    
    static func downloadAllSatsSkyView(datiJson: NSData) -> [Satellite]
    {
        var sats = [Satellite]()
        
        if let jsonArray = NetworkService.parseJSONFromData(datiJson as Data) {
            print(jsonArray)
            
            
            for i in jsonArray.keys {
                
                let id = i
                
               
                let actualSatId = id.dropFirst()
                var idInt = Int(actualSatId)
                if idInt == nil {
                    idInt = Int(id)
                } else {
                    idInt = Int(actualSatId)
                }
            
                let azimuth = jsonArray[i]!["azimuth"] as! Double
                let elevation = jsonArray[i]!["elevation"] as! Double
   
                let singleSat = Satellite.init(id: idInt!, gnssId: 2, timestamp: 0, validTimeStamp: 0, source: "skyView", numWords: 0, versione: 0, iTow: 0, manufacturer: "none", model: "none", dwrd: [], stato: false, checked: 0, osnma: "Validating...", azim: Int(azimuth), elev: Int(elevation), cno: 0, valid: false)
                sats.append(singleSat)
            }
        }
        return sats
    }

}

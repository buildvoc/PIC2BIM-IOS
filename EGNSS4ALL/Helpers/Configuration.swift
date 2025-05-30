//
//  Configuration.swift
//  EGNSS4ALL
//
//  Created by Mayur Shrivas on 27/02/24.
//

import Foundation

struct Configuration {
    
    static var baseURLString: String {
        /// Check if the custom server is enabled and customer server URL exists
        let customServer = UserDefaults.standard.bool(forKey: "customServer")
        if customServer,
            let url = UserDefaults.standard.string(forKey: "url") {
            return url
        } else {
            return "https://pic2bim.co.uk/"
        }
    }
}

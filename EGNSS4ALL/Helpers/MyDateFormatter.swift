//
//  DateHelper.swift
//  EGNSS4ALL
//
//  Created by IE12 on 07/03/24.
//

import Foundation

class MyDateFormatter {

    static let sharedInstance = DateFormatter()
    private init() {
    }

    static var yyyyMMdd: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_GB")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter
    }
}

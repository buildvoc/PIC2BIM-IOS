//
//  Answer.swift
//  PIC2BIM
//
//  Created by Mayur Shrivas on 06/05/24.
//

import UIKit

struct Answer: Decodable {
    var status: String
    var error_msg: String?
    var photos_ids: [Int]
}

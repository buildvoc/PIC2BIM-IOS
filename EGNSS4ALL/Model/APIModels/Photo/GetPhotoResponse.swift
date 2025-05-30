//
//  GetPhotoResponse.swift
//  EGNSS4ALL
//
//  Created by Mayur Shrivas on 14/03/24.
//

import Foundation

struct GetPhotoResponse: Decodable {
    var status: String
    var error_msg: String?
    var photo: Photo?
}

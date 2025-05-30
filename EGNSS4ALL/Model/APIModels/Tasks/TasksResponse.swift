//
//  TasksResponse.swift
//  EGNSS4ALL
//
//  Created by Mayur Shrivas on 14/03/24.
//

import Foundation

struct TasksResponse: Decodable {
    var status: String
    var error_msg: String?
    var tasks: [Task]?
}


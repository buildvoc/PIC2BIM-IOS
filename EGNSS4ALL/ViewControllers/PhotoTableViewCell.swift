//
//  PhotoTableViewCell.swift
//  EGNSS4CAP
//
//  
//

import UIKit

class PhotoTableViewCell: UITableViewCell {

    @IBOutlet weak var latValueLabel: UILabel!
    @IBOutlet weak var lngValueLabel: UILabel!
    @IBOutlet weak var createdValueLabel: UILabel!
    @IBOutlet weak var sendedValueLabel: UILabel!
    @IBOutlet weak var noteValueLabel: UILabel!
    @IBOutlet weak var photoImage: UIImageView!
    @IBOutlet weak var backView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}



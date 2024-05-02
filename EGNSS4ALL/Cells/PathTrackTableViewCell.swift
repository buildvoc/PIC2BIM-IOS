//
//  PathTrackTableViewCell.swift
//  GTPhotos
//
//

import UIKit

class PathTrackTableViewCell: UITableViewCell {
    
    static let indentifier = "PathTrackTableViewCell"
   
    

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var sentLabel: UILabel!
    
    @IBOutlet weak var kmlBtn: UIButton!
    override func awakeFromNib() {
        kmlBtn.layer.borderWidth = 1.0
        kmlBtn.layer.borderColor = UIColor.black.cgColor
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}



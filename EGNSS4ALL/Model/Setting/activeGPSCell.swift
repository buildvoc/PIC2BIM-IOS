//
//  activeGPSCell.swift
//  EGNSS4ALL
//
//  Created by Gabriele Amendola on 07/06/22.
//

import UIKit

class activeGPSCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var activeSW: UISwitch!
    
    var titolo: String! {
        didSet {
            self.updateUI()
        }
    }
    
    func updateUI() {
        titleLabel.text = titolo
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

//
//  WalkRequestsTableVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 06/02/2023.
//
//	Defines a table view cell in the walk requests VC (friend walks)

import UIKit

class WalkRequestsTableVC: UITableViewCell {
	
	@IBOutlet weak var cellView: UIView!
	
	@IBOutlet weak var profileImgView: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

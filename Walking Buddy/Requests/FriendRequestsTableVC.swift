//
//  FriendRequestsTableVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 06/02/2023.
//
//	Defines a table view cell in the friend requests VC

import UIKit

class FriendRequestsTableVC: UITableViewCell {
	
	@IBOutlet weak var cellView: UIView!
	
	@IBOutlet weak var profileImgView: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var xpLabel: UILabel!
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

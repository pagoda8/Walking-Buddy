//
//  ChallengeRequestsTableVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 09/02/2023.
//

import UIKit

class ChallengeRequestsTableVC: UITableViewCell {
	
	@IBOutlet weak var cellView: UIView!
	
	@IBOutlet weak var profileImgView: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

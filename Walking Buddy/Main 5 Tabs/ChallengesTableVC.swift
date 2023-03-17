//
//  ChallengesTableVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 10/02/2023.
//
//	Defines a cell for the table view in ChallengesVC

import UIKit

class ChallengesTableVC: UITableViewCell {
	
	@IBOutlet weak var cellView: UIView!
	
	@IBOutlet weak var imgView1: UIImageView!
	@IBOutlet weak var imgView2: UIImageView!
	@IBOutlet weak var name1Label: UILabel!
	@IBOutlet weak var xp1Label: UILabel!
	@IBOutlet weak var xp2Label: UILabel!
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

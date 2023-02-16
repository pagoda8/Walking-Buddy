//
//  AchievementsTableVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 15/02/2023.
//

import UIKit

class AchievementsTableVC: UITableViewCell {

	@IBOutlet weak var cellView: UIView!
	
	@IBOutlet weak var icon: UIImageView!
	@IBOutlet weak var name: UILabel!
	@IBOutlet weak var achievementDescription: UILabel!
	@IBOutlet weak var progressView: UIProgressView!
	@IBOutlet weak var progressLabel: UILabel!
	@IBOutlet weak var star1: UIImageView!
	@IBOutlet weak var star2: UIImageView!
	@IBOutlet weak var star3: UIImageView!
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

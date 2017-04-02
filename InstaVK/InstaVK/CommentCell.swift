//
//  CommentCell.swift
//  InstaVK
//
//  Created by Svyatoslav Bykov on 02.04.17.
//  Copyright © 2017 Svyatoslav Bykov. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var commentText: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    class func instanceFromNib() -> CommentCell {
        return UINib(nibName: "CommentCell", bundle: nil).instantiate(withOwner: self, options: nil)[0] as! CommentCell
    }
    
}

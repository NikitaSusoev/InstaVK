//
//  PictureCellTest.swift
//  InstaVK
//
//  Created by Svyatoslav Bykov on 29.04.17.
//  Copyright © 2017 Nikita Susoev. All rights reserved.
//

import UIKit

class PictureCellTest: UITableViewCell {

    
    @IBOutlet weak var pictureHeight: NSLayoutConstraint!
    @IBOutlet weak var postPicture: UIImageView!
    @IBOutlet weak var postUserAvatar: UIImageView!
    @IBOutlet weak var postUserFirstNameLastName: UILabel!
    
    //    #TO-DO
    //    Figure out why you should make outlet to PostPicture, but not to File's owner (causes crash at NewsScreen)

    
    var delegate: PictureCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func didTapCommentsButton(_ sender: UIButton) {
        if let delegate = self.delegate {
            delegate.didTapButton(sender: self)
        }
    }
}
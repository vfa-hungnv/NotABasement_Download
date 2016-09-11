//
//  FileCellController.swift
//  NotABaseM_Swift2
//
//  Created by Hung Nguyen on 9/11/16.
//  Copyright © 2016 Hung Nguyen. All rights reserved.
//

import UIKit

class FileCellController: UITableViewCell {
    
    @IBOutlet var fileName: UILabel!
    @IBOutlet var progress: UIProgressView!
    @IBOutlet var status: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    

}

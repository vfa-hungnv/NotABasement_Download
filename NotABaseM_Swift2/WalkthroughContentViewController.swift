//
//  ContentViewController.swift
//  NotABaseM_Swift2
//
//  Created by Hung Nguyen on 9/12/16.
//  Copyright © 2016 Hung Nguyen. All rights reserved.
//

import UIKit

class ContentViewController: UIViewController {
    

    @IBOutlet var contentImageView:UIImageView!
    @IBOutlet var pageControl:UIPageControl!
    @IBOutlet var forwardButton:UIButton!
    
    var index = 0
    var heading = ""
    var imageFile = UIImage()
    var content = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentImageView.image = imageFile

        forwardButton.setTitle("Skip", for: UIControlState())
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)

    }
    
}

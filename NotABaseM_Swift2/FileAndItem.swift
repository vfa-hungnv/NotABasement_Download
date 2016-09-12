//
//  FileAndItem.swift
//  AssigForNABM_Download
//
//  Created by Hung Nguyen on 9/10/16.
//  Copyright © 2016 Hung Nguyen. All rights reserved.
//

import Foundation
import SwiftyJSON


struct Image {
    var progress: Float = 0.0
    var urlString: String = ""
    // in pair link download and URL afterdownload
    var urlAndDestinationData = [String: NSURL]()
    
    init (urlStr: String) {
        urlAndDestinationData[urlStr] = nil
        urlString = urlStr
    }
}

struct File {

    var isDownloading = false
    var progress: Float {
        var sum: Float = 0.0
        for item in images {
            sum += item.progress
        }
        return sum / (Float)(images.count)
    }

    init(name: String?) {
        self.name = name!
    }
    
    var name: String = ""
    var status: String = "Click to download"
    var images = [Image]()
    
}

//
//  Download.swift
//  NotABaseM_Swift2
//
//  Created by Hung Nguyen on 9/12/16.
//  Copyright © 2016 Hung Nguyen. All rights reserved.
//

import Foundation

class DownloadController: NSObject {
    
    var name: String?
    var isDownload = false
    
    var url: NSURL?
    var progress: Float = 0.0
    var downloadTask: NSURLSessionDownloadTask?
    
    init(url :NSURL?) {
        self.url = url
    }
}
//
//  ManagerFiles.swift
//  AssigForNABM_Download
//
//  Created by Hung Nguyen on 9/10/16.
//  Copyright © 2016 Hung Nguyen. All rights reserved.
//

import Foundation

protocol ManagerFileAndDownloadProtocol {
    var files: [File]? {get set}
    var numberOfFiles: Int { get}
}

class ManagerFiles: ManagerFileAndDownloadProtocol {
    
    static let sharedInstance = ManagerFiles()
    
    fileprivate init() {
        files = []
        activeDownload = [String: URL]()
    }
    
    var numberOfFiles: Int  {
        get {
            if let files = files {
                return files.count
            }
            return 0
        }
    }
    
    var files: [File]?
    var activeDownload: [String: URL]?
}

//
//  ViewController.swift
//  NotABaseM_Swift2
//
//  Created by Hung Nguyen on 9/10/16.
//  Copyright © 2016 Hung Nguyen. All rights reserved.
//

import UIKit

import Alamofire
import Zip
import SwiftyJSON

class ViewController: UIViewController, NSURLSessionTaskDelegate {
    
    var dataTask: NSURLSessionDownloadTask?
    
    @IBOutlet var progress: UIProgressView!
    @IBOutlet var tableView: UITableView!
    
    var arrayTitleOfFile: [String] = []
    var jsonArray : [JSON] = []
    
    let fileManager = NSFileManager.defaultManager()
    
    var destination: NSURL?
    var fileFoderUrl: NSURL!
    let fileUrl = NSURL(string: "https://dl.dropboxusercontent.com/u/4529715/JSON%20files.zip")
    
    lazy var downloadsSession: NSURLSession = {
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("bgSessionConfiguration")
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        _ = self.downloadsSession
        dataTask = downloadsSession.downloadTaskWithURL(fileUrl!)
        
        self.progress.progress = 0.0
        self.progress.hidden = false
        startdownload()
        
    }
    
    private func loadImageTask(imageURL: NSURL, image: UIImageView) {
        let imageURL = NSURL(string: "http://submanga.org/resources/uploads/manga/boku-wa-kimi-no-shiro/capitulo/es/0/1.jpg")
        
        
        let imageTask = NSURLSession.sharedSession().dataTaskWithURL(imageURL!, completionHandler: {
            data, response, error in
            
            if let error = error {
                print(error.localizedDescription)
            } else if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    dispatch_async(dispatch_get_main_queue()) {
                        
                        image.image = UIImage(data: data!)
                        print("DM_ Set image done")
                    }
                } else {
                    print("DM_ Some thing wrong with response")
                }
            }
        })
        
        imageTask.resume()
    }
    
    private func startdownload() {
        
        dataTask?.resume()
    }
    
    private func stopDownload() {
        dataTask?.suspend()
    }
    
    private func unZipFile(location: NSURL) {
        do {
            
            let filePath = location
            _ = try Zip.quickUnzipFile(filePath)
            
            print("DM_ Unzip sucess")
        }
        catch {
            print("DM_ Something went wrong when unZip")
        }
    }
    
    private func isFileExistAtPath(filePath: NSURL?) -> Bool {
        return self.fileManager.fileExistsAtPath(filePath!.path!)
    }
    
    private func parseJson(folderOfJSONFile: NSURL?) {
        
        if ( isFileExistAtPath(folderOfJSONFile!)) {
            let files = try?  fileManager.contentsOfDirectoryAtURL(folderOfJSONFile!, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants)
            
            if let files = files {
                for file in files {
                    let stringJSON = try? NSString(contentsOfURL: file, encoding: NSUTF8StringEncoding)
                    
                    if let stringJSON = stringJSON {
                        if let dataFromString = stringJSON.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                            let json = JSON(data: dataFromString)
                            jsonArray.append(json)
                        }
                    } else {
                        print("DM_ Can not read string from JSON")
                    }
                }
            }
            
            if (jsonArray.count > 0) {
                print("DM_ 1st: \(jsonArray[0]), count: \(jsonArray.count)")
            }

        } else {
            print("\nDM_ File not in path")
        }
    }
    
    private func callBack_GetURLOfJsonFile(folderOfJSONFile: NSURL?) {
        if (isFileExistAtPath(folderOfJSONFile!)) {
            
            let filesURL = try?  fileManager.contentsOfDirectoryAtURL(folderOfJSONFile!, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants)
            if self.arrayTitleOfFile.count > 0 {
                self.arrayTitleOfFile.removeAll()
            }
            
            for file in filesURL! {
                let title = file.lastPathComponent!.localizedCapitalizedString
                self.arrayTitleOfFile.append(title)
            }
            
        } else {
            print("\nDM_ File not in path")
        }
    }

}
extension ViewController: NSURLSessionDownloadDelegate {
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
        fileFoderUrl = try! fileManager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        
        let lastPathComponent = self.fileUrl!.lastPathComponent!
        
        destination = fileFoderUrl.URLByAppendingPathComponent(lastPathComponent)
        
        if (self.fileManager.fileExistsAtPath((self.destination?.path)!)) {
            do {
                try self.fileManager.removeItemAtURL(self.destination!)
            } catch {
                print("DM_ Can not remove file existed")
            }
        }
        // Move and unzip file
        do {
            try self.fileManager.moveItemAtURL(location, toURL: self.destination!)
            self.unZipFile(self.destination!)
        } catch {
            print("DM_ Can not move file to destionation")
        }
        
        // check if forder after unzip have json file 
        let folderOfJSONFile = fileFoderUrl?.URLByAppendingPathComponent("JSON files/JSON files/")
        
        print("\nDM_ Download Done at: \n\(folderOfJSONFile)\n Now call back reload table")
        
        // After download parse JSON and reload table
        
        self.parseJson(folderOfJSONFile)
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.callBack_GetURLOfJsonFile(folderOfJSONFile)
            self.progress.hidden = true
            self.tableView.reloadData()
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        dispatch_async(dispatch_get_main_queue()) {
            let percent:Float = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            self.progress.progress = percent
        }
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return (self.arrayTitleOfFile.count)
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("fileCell", forIndexPath: indexPath) as! FileCellController
        cell.fileName.text = self.arrayTitleOfFile[indexPath.row]
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    
}















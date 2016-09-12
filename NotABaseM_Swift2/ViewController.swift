//
//  ViewController.swift
//  NotABaseM_Swift2
//
//  Created by Hung Nguyen on 9/10/16.
//  Copyright © 2016 Hung Nguyen. All rights reserved.
//

import UIKit
import Zip
import SwiftyJSON

class ViewController: UIViewController, NSURLSessionTaskDelegate {
    
    var dataTask: NSURLSessionDownloadTask?
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var controlButton: UIButton!
    @IBOutlet var startButton: UIBarButtonItem!
    let fileManager = NSFileManager.defaultManager()
    
    @IBOutlet var slider: UISlider!
    @IBOutlet var sliderNumber: UILabel!
    
    @IBOutlet var percentLabel: UILabel!
    var destination: NSURL?
    var fileFoderUrl: NSURL!
    let fileUrl = NSURL(string: "https://dl.dropboxusercontent.com/u/4529715/JSON%20files.zip")
    var imagesUrl = NSURL(string: "")
    
    lazy var downloadsSession: NSURLSession = {
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("add")
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()
    var numberOfDownloadFile: Int = 1
    lazy var downloadsImagesSession: NSURLSession = {
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("images")
        configuration.HTTPMaximumConnectionsPerHost = 4
        configuration.timeoutIntervalForRequest = 5
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()
    
    
    
    
    // Hander slider
    var numbers = [1, 2, 3, 4]
    var oldIndex = 0
    // 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        _ = self.downloadsSession
        print("DM_ Number of file in viewDidLoad: \(ManagerFiles.sharedInstance.numberOfFiles)")
        
        //MARK:  DM_ For Debug
        //addTapped(UIButton())
        
        //Get number in slide bar to set Number of file download at times
        let numberOfSteps = Float(numbers.count - 1)
        slider!.maximumValue = numberOfSteps;
        slider!.minimumValue = 0;
        
        //  the slider moves it will continously call the -valueChanged:
        slider!.continuous = true; //
        slider!.addTarget(self, action: #selector(ViewController.valueChanged(_:)), forControlEvents: .ValueChanged)
        
        controlButton.titleLabel?.text = "Start"
        
    }
    
    func valueChanged(sender: UISlider) {
        // round the slider position to the nearest index of the numbers array
        let index = (Int)(slider!.value + 0.5);
        slider?.setValue(Float(index), animated: false)
        let number = numbers[index]
        if oldIndex != index{
            print("sliderIndex:\(index)")
            print("number: \(number)")
            sliderNumber.text = "Number: \(number)"
            oldIndex = index
            numberOfDownloadFile = numbers[index]
        }
    }
    
    @IBAction func controlButtonTapped(sender: AnyObject) {
        print("DM Button: \(controlButton.titleLabel?.text )")
        if(controlButton.titleLabel?.text == "Start") {
            
            dowloadAllImages()
        } else {
            
            dataTask?.suspend()
        }
    }
    
    
    @IBAction func addTapped(sender: AnyObject) {
        self.navigationItem.title = "Adding Files..."
        dataTask = downloadsSession.downloadTaskWithURL(fileUrl!)
        dataTask?.resume()
    }
    
    
    @IBAction func resetTapped(sender: AnyObject) {
        self.navigationItem.title = "Files"
        dataTask?.cancel()
        
        self.resetTableAndDeleteInManagerFile()
    }
    
    private func resetTableAndDeleteInManagerFile() {
        if (ManagerFiles.sharedInstance.files?.count > 0) {
            ManagerFiles.sharedInstance.files?.removeAll()
            tableView.reloadData()
        }
    }
    

    
    private func dowloadAllImages () {
        if let files = ManagerFiles.sharedInstance.files {
            if files.count > 0 {
                for file in files {
                    startDownloadImages(file)
                }
            } else {
                let alert = UIAlertController(title: "Not have file to download", message: "Add file first", preferredStyle: .Alert)
                let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
                alert.addAction(action)
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    // Download all images in files
    private func startDownloadImages(file: File) {
        for image in file.images {
                
            //print("\nDM_ Downloading: \(image.urlString)")
            ManagerFiles.sharedInstance.activeDownload![image.urlString] = nil
            dataTask = downloadsImagesSession.downloadTaskWithURL(NSURL(string: image.urlString)!)
            
            dataTask?.resume()
        }
          print("\nDM_ Downloading: file\(file.name)")
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
    
    // MARK: 2 Download helper methods
    
    private func isFileExistAtPath(filePath: NSURL?) -> Bool {
        return self.fileManager.fileExistsAtPath(filePath!.path!)
    }
    
    private func localFilePathForUrl(imageURL: String) -> NSURL? {
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        if let url = NSURL(string: imageURL), let lastPathComponent = url.lastPathComponent {
            let fullPath = documentsPath.stringByAppendingPathComponent(lastPathComponent)
            return NSURL(fileURLWithPath:fullPath)
        }
        return nil
    }
    var totalImages = 0.0
    private func callBack_GetURLOfJsonFile_SetDataToManagerFile(folderOfJSONFile: NSURL?) {
        var totalFiles = 0.0
        if ( isFileExistAtPath(folderOfJSONFile!)) {
            
            // Read the folder to get array of json file
            let arrayOfFile = try?  fileManager.contentsOfDirectoryAtURL(folderOfJSONFile!, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants)
            
            if let files = arrayOfFile {
                for file in files {
                    let stringJSON = try? NSString(contentsOfURL: file, encoding: NSUTF8StringEncoding)
                    
                    if let stringJSON = stringJSON {
                        if let dataFromString = stringJSON.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                            let jsons = JSON(data: dataFromString)
                            
                            var fileStruct = File(name: file.lastPathComponent!.localizedCapitalizedString)
                            
                            // Now add image to file, file to manager, image create by the urlDonwloadLink
                            
                            // Add image to file
                            for urlString in jsons.array! {
                                let image = Image(urlStr: urlString.string!)
                                totalFiles += 1.0
                                fileStruct.images.append(image)
                            }
                            // Add file to managerFiles
                            ManagerFiles.sharedInstance.files?.append(fileStruct)
                            
                        }
                    } else {
                        print("DM_ Can not read string from JSON")
                    }
                }
                ////MARK:  For Debug
                //self.startTapped(UIBarButtonItem())
                totalImages = (totalFiles)
                print("DM_ File count:\(files.count)")
            }
            
            
        } else {
            print("\nDM_ File not in path")
        }
    }

}

extension ViewController: NSURLSessionDownloadDelegate {
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
        let indentifer = session.configuration.identifier
        
        switch indentifer! {
        case "add":
            // Move and unzip file
            do {
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
                try self.fileManager.moveItemAtURL(location, toURL: self.destination!)
                self.unZipFile(self.destination!)
                
                // check if forder after unzip have json file
                let folderOfJSONFile = fileFoderUrl?.URLByAppendingPathComponent("JSON files/JSON files/")
                
                print("\nDM_ Download and unzip at susscess full")
                //print("\nDM_ Destination of files: \(destination)")
                dispatch_async(dispatch_get_main_queue()) {
                    
                    self.callBack_GetURLOfJsonFile_SetDataToManagerFile(folderOfJSONFile)
                    self.navigationItem.title = "Files"
                    self.tableView.reloadData()
                }
            } catch {
                print("DM_ Can not move file to destionation")
            }
        case "images":
            // Move
            if let originalURL = downloadTask.originalRequest?.URL?.absoluteString,
                let destinationURL = localFilePathForUrl(originalURL) {

                let fileManager = NSFileManager.defaultManager()
                do {
                    try fileManager.removeItemAtURL(destinationURL)
                } catch {
                    // file probably doesn't exist
                }
                do {
                    try fileManager.copyItemAtURL(location, toURL: destinationURL)
                    
                    ManagerFiles.sharedInstance.activeDownload![originalURL] = destinationURL
                    //For debug
                    //print("\nDM_ Download done: \(destinationURL)")
                } catch let error as NSError {
                    print("Could not copy file to disk: \(error.localizedDescription)")
                }
            }
            print("Dm_ Total: \(totalImages)")
            print("DM_ Total FileDone Count: \(ManagerFiles.sharedInstance.activeDownload?.count)")
            let progress = Float((ManagerFiles.sharedInstance.activeDownload?.count)!)/Float(totalImages)
            dispatch_async(dispatch_get_main_queue()) {
                self.navigationItem.title = "Files"
                self.tableView.reloadData()
                self.percentLabel.text =  String(format: "%.1f%%",  progress * 100)
            }
        default:
            print("DM_ Not hander yet!!!!")
            break
        }
        
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        //let indentifer = session.configuration.identifier

    }
}

extension ViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let files = ManagerFiles.sharedInstance.files {
            return files.count
        }
        
        return 1
    }
    

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("fileCell", forIndexPath: indexPath) as! FileCellController
        if let files = ManagerFiles.sharedInstance.files {
            cell.fileName.text = files[indexPath.row].name
            cell.status.text = files[indexPath.row].status
        }
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("DM_ Select at \(indexPath.row)")
        if let controller = self.storyboard?.instantiateViewControllerWithIdentifier("ImagesCollectionController") as? ImagesCollectionController {
            controller.numberOfFile = indexPath.row
            if let files = ManagerFiles.sharedInstance.files {
                controller.file = files[indexPath.row]
            }
            
            self.navigationController?.pushViewController(controller, animated: true)
            
        }
    }
}

extension ViewController: NSURLSessionDelegate {
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            if let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                appDelegate.backgroundSessionCompletionHandler = nil
                
                if (appDelegate.indentiferDownload == "bgSessionConfiguration") {
                    print("DM_ bgSessionConfiguration")
                } else if (appDelegate.indentiferDownload == "bgSessionImagesConfiguration"){
                    print("DM_ bgSessionImagesConfiguration")
                }
                dispatch_async(dispatch_get_main_queue(), {
                    self.controlButton.titleLabel?.text = "Start"
                    completionHandler()
                })
            }
        }
    }
}













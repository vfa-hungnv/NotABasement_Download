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

    let fileFoderUrl: NSURL = try! NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
    let fileUrl = NSURL(string: "https://dl.dropboxusercontent.com/u/4529715/JSON%20files.zip")
    var imagesUrl = NSURL(string: "")
    
    lazy var downloadsSession: NSURLSession = {
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("background")
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()
    var numberOfImageDownloadAtOne: Int = 1
    var numberOfImageDownloaded = 1
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
            numberOfImageDownloadAtOne = numbers[index]
        }
    }
    
    @IBAction func controlButtonTapped(sender: AnyObject) {
        print("DM Button: \(controlButton.titleLabel?.text )")
        if(controlButton.titleLabel?.text == "Start") {
            controlButton.titleLabel?.text = "Pause"
            dowloadAllImages()
        } else if (controlButton.titleLabel?.text == "Pause"){
            controlButton.titleLabel?.text = "Start"
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
                
                let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                
                dispatch_async(backgroundQueue, {
                    print("This is run on the background queue")
                    for file in files {
                        self.startDownloadImages(file)
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.controlButton.titleLabel?.text = "Start"
                    })
                })
                
                
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
                
            //print("\nDM_Start download Image: \(image.urlString)")
            ManagerFiles.sharedInstance.activeDownload![image.urlString] = nil
            dataTask = downloadsSession.downloadTaskWithURL(NSURL(string: image.urlString)!)
            
            dataTask?.resume()
        }
        print("\nDM_ Start downloading file: \(file.name)")
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
        
        
        if let currentURL = downloadTask.currentRequest?.URL,
            let currentURLString = downloadTask.currentRequest?.URL?.absoluteString,
            let fileExtention = currentURLString.componentsSeparatedByString(".").last,
            let lastComponent = currentURL.lastPathComponent {
            
            print("\(currentURL), \(fileExtention)")
            do {
                var destination = fileFoderUrl.URLByAppendingPathComponent(lastComponent)
                
                if (self.fileManager.fileExistsAtPath((destination.path)!)) {
                    try! self.fileManager.removeItemAtURL(destination)
                }
                try self.fileManager.moveItemAtURL(location, toURL: destination)
                //
                if (fileExtention == "zip") {
                    self.unZipFile(destination)
                    destination = fileFoderUrl.URLByAppendingPathComponent("JSON files/JSON files/")
                    print("\nDM_ Download and unzip at susscess full: \(destination)")
                    self.callBack_GetURLOfJsonFile_SetDataToManagerFile(destination)
                } else {
                    numberOfImageDownloaded += 1
                    ManagerFiles.sharedInstance.activeDownload![currentURLString] = destination
                    print("DM_ Total FileDone Count: \(ManagerFiles.sharedInstance.activeDownload?.count)")
                }
                dispatch_async(dispatch_get_main_queue()) {
                    self.navigationItem.title = "Files"
                    self.tableView.reloadData()
                }
            } catch {
                print("DM_ Can not move file to destionation")
            }
        }
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













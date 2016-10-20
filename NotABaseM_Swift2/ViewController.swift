//
//  ViewController.swift
//  NotABaseM_Swift2
//
//  Created by Hung Nguyen on 9/10/16.
//  Copyright © 2016 Hung Nguyen. All rights reserved.
//

import UIKit
import SSZipArchive
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}



class ViewController: UIViewController, URLSessionTaskDelegate {
    
    var dataTask: URLSessionDownloadTask?
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var controlButton: UIButton!
    @IBOutlet var startButton: UIBarButtonItem!
    let fileManager = FileManager.default
    
    @IBOutlet var slider: UISlider!
    @IBOutlet var sliderNumber: UILabel!
    
    @IBOutlet var percentLabel: UILabel!

    let fileFoderUrl: URL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let fileUrl = URL(string: "https://dl.dropboxusercontent.com/u/4529715/JSON%20files.zip")
    var imagesUrl = URL(string: "")
    
    lazy var downloadsSession: Foundation.URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "background")
        configuration.httpMaximumConnectionsPerHost = 4
        configuration.timeoutIntervalForRequest = 20
        let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
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
        slider!.isContinuous = true; //
        slider!.addTarget(self, action: #selector(ViewController.valueChanged(_:)), for: .valueChanged)
        
        controlButton.titleLabel?.text = "Start"
        
        
    }
    
    func valueChanged(_ sender: UISlider) {
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
    
    @IBAction func controlButtonTapped(_ sender: AnyObject) {
        print("DM Button: \(controlButton.titleLabel?.text )")
        if(controlButton.titleLabel?.text == "Start") {
            controlButton.titleLabel?.text = "Pause"
            dowloadAllImages()
        } else if (controlButton.titleLabel?.text == "Pause"){
            controlButton.titleLabel?.text = "Start"
            dataTask?.suspend()
        }
    }
    
    
    @IBAction func addTapped(_ sender: AnyObject) {
        self.navigationItem.title = "Adding Files..."
        dataTask = downloadsSession.downloadTask(with: fileUrl!)
        dataTask?.resume()
    }
    
    
    @IBAction func resetTapped(_ sender: AnyObject) {
        self.navigationItem.title = "Files"
        
        //dataTask?.cancel()
        
        downloadsSession.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
        
        percentLabel.text = "Stop and clear. Done!!"
        self.resetTableAndDeleteInManagerFile()
    }
    
    fileprivate func resetTableAndDeleteInManagerFile() {
        if (ManagerFiles.sharedInstance.files?.count > 0) {
            ManagerFiles.sharedInstance.files?.removeAll()
            tableView.reloadData()
        }
    }
    
    fileprivate func dowloadAllImages () {
        if let files = ManagerFiles.sharedInstance.files {
            if files.count > 0 {
                
                let qualityOfServiceClass = DispatchQoS.QoSClass.background
                let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
                
                backgroundQueue.async(execute: {
                    print("This is run on the background queue")
                    for file in files {
                        self.startDownloadImages(file)
                    }
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.controlButton.titleLabel?.text = "Start"
                    })
                })
                
                
            } else {
                let alert = UIAlertController(title: "Not have file to download", message: "Add file first", preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(action)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // Download all images in files
    fileprivate func startDownloadImages(_ file: File) {
        for image in file.images {
                
            //print("\nDM_Start download Image: \(image.urlString)")
            ManagerFiles.sharedInstance.activeDownload![image.urlString] = nil
            dataTask = downloadsSession.downloadTask(with: URL(string: image.urlString)!)
            
            dataTask?.resume()
        }
        print("\nDM_ Start downloading file: \(file.name)")
    }
    
    fileprivate func unZipFile(_ location: URL) {
        do {
            
            let filePath = location.absoluteString
            SSZipArchive.unzipFile(atPath: filePath, toDestination: "\(filePath)/JSON File")

            
            print("DM_ Unzip sucess")
        }
        catch {
            print("DM_ Something went wrong when unZip")
        }
    }
    
    // MARK: 2 Download helper methods
    
    fileprivate func isFileExistAtPath(_ filePath: URL?) -> Bool {
        return self.fileManager.fileExists(atPath: filePath!.path)
    }
    
    fileprivate func localFilePathForUrl(_ imageURL: String) -> URL? {
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        if let url = URL(string: imageURL), let lastPathComponent = url.lastPathComponent {
            let fullPath = documentsPath.appendingPathComponent(lastPathComponent)
            return URL(fileURLWithPath:fullPath)
        }
        return nil
    }
    
    var totalImages = 0.0
    
    fileprivate func callBack_GetURLOfJsonFile_SetDataToManagerFile(_ folderOfJSONFile: URL?) {
        let totalFiles = 0.0
        if ( isFileExistAtPath(folderOfJSONFile!)) {
            
            // Read the folder to get array of json file
            let arrayOfFile = try?  fileManager.contentsOfDirectory(at: folderOfJSONFile!, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants)
            
            if let files = arrayOfFile {
                for file in files {
                    let stringJSON = try? NSString(contentsOf: file, encoding: String.Encoding.utf8.rawValue)
                    
                    if let stringJSON = stringJSON {
                        if stringJSON.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) != nil {
                            // TODO
                            //let jsons = JSON(data: dataFromString)
                            
                            let fileStruct = File(name: file.lastPathComponent.localizedCapitalizedString)
           
                            
                            // Now add image to file, file to manager, image create by the urlDonwloadLink
                            
                            // Add image to file
                            // TODO
//                            for urlString in jsons.array! {
//                                let image = Image(urlStr: urlString.string!)
//                                totalFiles += 1.0
//                                fileStruct.images.append(image)
//                            }
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

extension ViewController: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        
        if let currentURL = downloadTask.currentRequest?.url,
            let currentURLString = downloadTask.currentRequest?.url?.absoluteString,
            let fileExtention = currentURLString.components(separatedBy: ".").last,
            let lastComponent = currentURL.lastPathComponent {
            
            //print("\(currentURL), \(fileExtention)")
            do {
                var destination = fileFoderUrl.appendingPathComponent(lastComponent)
                
                if (self.fileManager.fileExists(atPath: (
                    destination!.path)!)) {
                    try! self.fileManager.removeItem(at: destination!)
                }
                try self.fileManager.moveItem(at: location, to: destination!)
                //
                if (fileExtention == "zip") {
                    self.unZipFile(destination!)
                    destination = fileFoderUrl.appendingPathComponent("JSON files/JSON files/")
                    print("\nDM_ Download and unzip at susscess full: \(destination)")
                    self.callBack_GetURLOfJsonFile_SetDataToManagerFile(destination)
                } else {
                    numberOfImageDownloaded += 1
                    ManagerFiles.sharedInstance.activeDownload![currentURLString] = destination
                    print("DM_ Total FileDone Count: \(ManagerFiles.sharedInstance.activeDownload?.count)")
                }
                DispatchQueue.main.async {
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let files = ManagerFiles.sharedInstance.files {
            return files.count
        }
        
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileCell", for: indexPath) as! FileCellController
        if let files = ManagerFiles.sharedInstance.files {
            cell.fileName.text = files[(indexPath as NSIndexPath).row].name
            cell.status.text = files[(indexPath as NSIndexPath).row].status
        }
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("DM_ Select at \((indexPath as NSIndexPath).row)")
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "ImagesCollectionController") as? ImagesCollectionController {
            controller.numberOfFile = (indexPath as NSIndexPath).row
            if let files = ManagerFiles.sharedInstance.files {
                controller.file = files[(indexPath as NSIndexPath).row]
            }
            
            self.navigationController?.pushViewController(controller, animated: true)
            
        }
    }
}

extension ViewController: URLSessionDelegate {
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                appDelegate.backgroundSessionCompletionHandler = nil
                
                if (appDelegate.indentiferDownload == "bgSessionConfiguration") {
                    print("DM_ bgSessionConfiguration")
                } else if (appDelegate.indentiferDownload == "bgSessionImagesConfiguration"){
                    print("DM_ bgSessionImagesConfiguration")
                }
                DispatchQueue.main.async(execute: {
                    //self.controlButton.titleLabel?.text = "Start"
                    print("DM_ All File Done")
                    completionHandler()
                })
            }
        }
    }
}





//WalkthroughPageViewController *pageView = (WalkthroughPageViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"WalkthroughController"];
//if (pageView != nil) {
//    [self presentViewController:pageView animated:YES completion:nil];
//}







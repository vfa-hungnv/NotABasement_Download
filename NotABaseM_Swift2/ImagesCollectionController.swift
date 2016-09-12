//
//  CollectionImagesController.swift
//  NotABaseM_Swift2
//
//  Created by Hung Nguyen on 9/11/16.
//  Copyright © 2016 Hung Nguyen. All rights reserved.
//


import UIKit
import CoreGraphics

class ImagesCollectionController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource{
    var file = File(name: "")
    var numberOfFile = -1
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        let button = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: #selector(ImagesCollectionController.reloadCollectionview))
        self.navigationItem.rightBarButtonItem = button
        
    }
    
    func reloadCollectionview() {
        collectionView.reloadData()
    }
    @IBOutlet var collectionView: UICollectionView!
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if file.images.count > 0 {
            return file.images.count
        }
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("imagesCell", forIndexPath: indexPath) as! ImageCell
            //let pdf = UIPDF
            let imageDownloadURL = file.images[indexPath.row].urlString
            if let imageDowloadedURL = ManagerFiles.sharedInstance.activeDownload![imageDownloadURL] {
                let extention = imageDowloadedURL.lastPathComponent
                print("DM_ Format: \(extention)")
                

                
                if let imageData = NSData(contentsOfURL: imageDowloadedURL) {
                    print("DM_ Images from filelink: \(imageDowloadedURL.absoluteString)")
                    cell.imagesCell.image = UIImage(data: imageData)
                }
            }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let pageViewController = storyboard?.instantiateViewControllerWithIdentifier("WalkthroughController") as? WalkthroughPageViewController {
            presentViewController(pageViewController, animated: true, completion: nil)
        }
    }
}









//
//  CollectionImagesController.swift
//  NotABaseM_Swift2
//
//  Created by Hung Nguyen on 9/11/16.
//  Copyright © 2016 Hung Nguyen. All rights reserved.
//


import UIKit
import CoreGraphics

class ImagesCollectionController: UIViewController{
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
    
    private func drawPDFfromURL(url: NSURL) -> UIImage? {
        guard let document = CGPDFDocumentCreateWithURL(url) else { return nil }
        guard let page = CGPDFDocumentGetPage(document, 1) else { return nil }
        
        let pageRect = CGPDFPageGetBoxRect(page, .MediaBox)
        
        UIGraphicsBeginImageContextWithOptions(pageRect.size, true, 0)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
        CGContextFillRect(context,pageRect)
        
        CGContextTranslateCTM(context, 0.0, pageRect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        CGContextDrawPDFPage(context, page);
        let img = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return img
    }
}

extension ImagesCollectionController: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let pageViewController = storyboard?.instantiateViewControllerWithIdentifier("PageViewController") as? PageViewController {
            pageViewController.indexOffile = indexPath.row
            presentViewController(pageViewController, animated: true, completion: nil)
        }
    }
}
extension ImagesCollectionController: UICollectionViewDataSource {
    
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
            let extention = imageDowloadedURL.lastPathComponent?.componentsSeparatedByString(".").last
            // For debug
            print("DM_ Format: \(extention)")
            
            if extention == "pdf" {
                if let _ = drawPDFfromURL(imageDowloadedURL) {
                    cell.imagesCell.image = drawPDFfromURL(imageDowloadedURL)
                }
            } else {
                if let imageData = NSData(contentsOfURL: imageDowloadedURL) {
                    cell.imagesCell.image = UIImage(data: imageData)
                }
            }
        }
        return cell
    }
}






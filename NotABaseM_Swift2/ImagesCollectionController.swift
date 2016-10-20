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
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        let button = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(ImagesCollectionController.reloadCollectionview))
        self.navigationItem.rightBarButtonItem = button
        
    }
    
    func reloadCollectionview() {
        collectionView.reloadData()
    }
    @IBOutlet var collectionView: UICollectionView!
    
    fileprivate func drawPDFfromURL(_ url: URL) -> UIImage? {
        guard let document = CGPDFDocument(url) else { return nil }
        guard let page = document.page(at: 1) else { return nil }

        
        let pageRect = page.getBoxRect(.mediaBox)
        
        UIGraphicsBeginImageContextWithOptions(pageRect.size, true, 0)
        let context = UIGraphicsGetCurrentContext()
        
        context!.setFillColor(UIColor.white.cgColor)
        context!.fill(pageRect)
        
        context!.translateBy(x: 0.0, y: pageRect.size.height);
        context!.scaleBy(x: 1.0, y: -1.0);
        
        context!.drawPDFPage(page);
        let img = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return img
    }
}

extension ImagesCollectionController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let pageViewController = storyboard?.instantiateViewController(withIdentifier: "PageViewController") as? PageViewController {
            pageViewController.indexOffile = (indexPath as NSIndexPath).row
            present(pageViewController, animated: true, completion: nil)
        }
    }
}
extension ImagesCollectionController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if file.images.count > 0 {
            return file.images.count
        }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imagesCell", for: indexPath) as! ImageCell
        //let pdf = UIPDF
        let imageDownloadURL = file.images[(indexPath as NSIndexPath).row].urlString
        if let imageDowloadedURL = ManagerFiles.sharedInstance.activeDownload![imageDownloadURL] {
            let extention = imageDowloadedURL.lastPathComponent?.components(separatedBy: ".").last

            print("DM_ Format: \(extention)")
            
            if extention == "pdf" {
                if let _ = drawPDFfromURL(imageDowloadedURL as URL) {
                    cell.imagesCell.image = drawPDFfromURL(imageDowloadedURL as URL)
                }
            } else {
                if let imageData = try? Data(contentsOf: imageDowloadedURL as URL) {
                    cell.imagesCell.image = UIImage(data: imageData)
                }
            }
        }
        return cell

    }
}






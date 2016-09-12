//
//  WalkthroughPageViewController.swift
//  NotABaseM_Swift2
//
//  Created by Hung Nguyen on 9/12/16.
//  Copyright © 2016 Hung Nguyen. All rights reserved.
//

import UIKit

class PageViewController: UIPageViewController, UIPageViewControllerDataSource {
    var indexOffile = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        
        if let startingViewController = viewControllerAtIndex(0) {
            setViewControllers([startingViewController], direction: .Forward, animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    // MARK: - UIPageViewControllerDataSource
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        var index = (viewController as! ContentViewController).index
        index += 1
        
        return viewControllerAtIndex(index)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        var index = (viewController as! ContentViewController).index
        index -= 1
        
        return viewControllerAtIndex(index)
    }
    
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
    
    func viewControllerAtIndex(index: Int) -> ContentViewController? {
        
        if index == NSNotFound || index < 0 {
            return nil
        }
        
        // Create a new view controller and pass suitable data.
        if let pageContentViewController = storyboard?.instantiateViewControllerWithIdentifier("ContentViewController") as? ContentViewController {

            pageContentViewController.index = index
            
            if let files = ManagerFiles.sharedInstance.files {
                
                let imageDownloadURL = files[indexOffile].images[index].urlString
                
                if let imageDowloadedURL = ManagerFiles.sharedInstance.activeDownload![imageDownloadURL] {
                    print("DM_ donwloaded at: \(imageDowloadedURL)")
                    let extention = imageDowloadedURL.lastPathComponent?.componentsSeparatedByString(".").last
                    // For debug
                    print("DM_ Format: \(extention)")
                    if extention == "pdf" {
                        if let _ = drawPDFfromURL(imageDowloadedURL) {
                            pageContentViewController.imageFile = drawPDFfromURL(imageDowloadedURL)!
                        }
                    } else {
                        if let imageData = NSData(contentsOfURL: imageDowloadedURL) {
                            pageContentViewController.imageFile = UIImage(data: imageData)!
                        }
                    }
                }
            }
            
            
            return pageContentViewController
        }
        
        return nil
    }
    
    func forward(index:Int) {
        if let nextViewController = viewControllerAtIndex(index + 1) {
            setViewControllers([nextViewController], direction: .Forward, animated: true, completion: nil)
        }
    }
}


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
            setViewControllers([startingViewController], direction: .forward, animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    // MARK: - UIPageViewControllerDataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        var index = (viewController as! ContentViewController).index
        index += 1
        
        return viewControllerAtIndex(index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        var index = (viewController as! ContentViewController).index
        index -= 1
        
        return viewControllerAtIndex(index)
    }
    
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
    
    func viewControllerAtIndex(_ index: Int) -> ContentViewController? {
        
        if index == NSNotFound || index < 0 {
            return nil
        }
        
        // Create a new view controller and pass suitable data.
        if let pageContentViewController = storyboard?.instantiateViewController(withIdentifier: "ContentViewController") as? ContentViewController {

            pageContentViewController.index = index
            
            if let files = ManagerFiles.sharedInstance.files {
                
                let imageDownloadURL = files[indexOffile].images[index].urlString
                
                if let imageDowloadedURL = ManagerFiles.sharedInstance.activeDownload![imageDownloadURL] {
                    print("DM_ donwloaded at: \(imageDowloadedURL)")
                    let extention = imageDowloadedURL.lastPathComponent?.components(separatedBy: ".").last
                    // For debug
                    print("DM_ Format: \(extention)")
                    if extention == "pdf" {
                        if let _ = drawPDFfromURL(imageDowloadedURL as URL) {
                            pageContentViewController.imageFile = drawPDFfromURL(imageDowloadedURL as URL)!
                        }
                    } else {
                        if let imageData = try? Data(contentsOf: imageDowloadedURL as URL) {
                            pageContentViewController.imageFile = UIImage(data: imageData)!
                        }
                    }
                }
            }
            
            
            return pageContentViewController
        }
        
        return nil
    }
    
    func forward(_ index:Int) {
        if let nextViewController = viewControllerAtIndex(index + 1) {
            setViewControllers([nextViewController], direction: .forward, animated: true, completion: nil)
        }
    }
}


//
//  ImageDownloadManager.swift
//
//  Created by Jonathan Gerber on 11/17/14.
//

import Foundation
import UIKit

enum ImageState {
    case New, Downloaded, Failed
}

class ImageDownloadManager: NSObject {
    
    let pendingOperations = PendingImageDownloadOperations()
    
    //Singleton object
    class var sharedInstance: ImageDownloadManager {
        struct Static {
            static var instance: ImageDownloadManager?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = ImageDownloadManager()
        }
        
        return Static.instance!
    }
    
    
    func startDownloadForImage(image: ServerImage, completionHandler: ((UIImage) -> Void)){

        //check if we're already downloading this image
        if let downloadOperation = self.pendingOperations.downloadsInProgress[image.url.absoluteString!] as? ImageDownloader {
            if (downloadOperation.image.state == .Downloaded) {
                if let img = downloadOperation.image.image {
                    completionHandler(img)
                }
            }
            return
        }
        
        //Set up the download operation
        let downloader = ImageDownloader(image: image)
        downloader.completionBlock = {
            if let img = image.image {
                completionHandler(img)
            }
        }

        //Start the download operation
        self.pendingOperations.downloadsInProgress[image.url.absoluteString!] = downloader
        self.pendingOperations.downloadQueue.addOperation(downloader)
        
    }
    
    
}


class ServerImage {
    let url:NSURL
    var state = ImageState.New
    var image = UIImage(named: "Placeholder")
    
    init(url:NSURL) {
        self.url = url
    }
}


class PendingImageDownloadOperations {
    
    lazy var downloadsInProgress = Dictionary<String,NSOperation>()
    
    lazy var downloadQueue:NSOperationQueue = {
        
        var queue = NSOperationQueue()
        queue.name = "Download queue"
        return queue
        
    }()
    
}


class ImageDownloader: NSOperation {
    let image: ServerImage
    
    init(image: ServerImage) {
        self.image = image
    }
    
    override func main() {
        autoreleasepool {
            
            if self.cancelled {
                return
            }

            let imageData = NSData(contentsOfURL:self.image.url)
            
            if self.cancelled {
                return
            }
            
            if imageData?.length > 0 {
                self.image.image = UIImage(data:imageData!)
                self.image.state = .Downloaded
            }
            else
            {
                self.image.state = .Failed
            }
        }
    }
}



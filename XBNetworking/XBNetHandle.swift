//
//  XBNetHandle.swift
//  XBHttpHandle
//
//  Created by xxb on 2017/1/7.
//  Copyright © 2017年 xxb. All rights reserved.
//

import UIKit

class XBNetHandle: NSObject {
    /// 单例
    static let shared = XBNetHandle()
    private override init() {}
    
    lazy var session:URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "XBNetHandle")
        let ses = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
        return ses
    }()
}


// MARK: - get、post请求
extension XBNetHandle {
    
    /*----- get请求 -----*/
    class func getRequestWithUrlStr(urlStr:String?,successBlock:@escaping (_ data:Data?)->Void,failureBlock:@escaping (_ error:Error?)->Void) ->Void
    {
        if urlStr != nil && urlStr?.isEmpty==false
        {
            let url = URL(string: urlStr!)
            let request = URLRequest(url: url!)
            let session = URLSession.shared
            let task = session.dataTask(with: request, completionHandler: { (data:Data?,response:URLResponse?,error:Error?)->Void in
                print("\rGET请求\r请求链接是：\(urlStr!)")
                print("请求结果是：\(data)")
                DispatchQueue.main.async(execute: {
                    if error != nil
                    {
                        failureBlock(error)
                    }
                    else if data != nil
                    {
                        successBlock(data)
                    }
                })
            })
            task.resume()
        }
    }
    
    /*----- post请求 -----*/
    class func postRequestWithUrlStr(urlStr:String?,params:[String:String]?,successBlock:@escaping (_ data:Data?)->Void,failureBlock:@escaping (_ error:Error?)->Void) ->Void
    {
        if urlStr != nil && urlStr?.isEmpty == false
        {
            if params == nil || (params?.count)! < 1
            {
                XBNetHandle.getRequestWithUrlStr(urlStr: urlStr, successBlock: successBlock, failureBlock: failureBlock)
                return
            }
            
            let url = URL(string: urlStr!)
            
            var request = URLRequest(url: url!)
            request.httpMethod="POST"
            
            var paramsStr = ""
            for (key,value) in params!
            {
                paramsStr += key+value+"&"
            }
            paramsStr += "type=JSON"
            request.httpBody=paramsStr.data(using: String.Encoding.utf8)
            
            let session = URLSession.shared
            let task = session.dataTask(with: request, completionHandler: { (data:Data?,response:URLResponse?,error:Error?)->Void
                in
                DispatchQueue.main.async(execute: {
                    if error != nil
                    {
                        failureBlock(error)
                    }
                    else if data != nil
                    {
                        successBlock(data)
                    }
                })
                
                print("\rPOST请求\r请求链接是：\(urlStr)\r请求参数是：\(paramsStr)")
                print("转成get请求：\(url)?\(paramsStr)")
                print("请求结果是：\(data)")
            })
            task.resume()
        }
    }
}

// MARK: - 下载方法
extension XBNetHandle {
    
    class func downFileWith(xbTask:XBDownloadTask) ->Void
    {
        let savePath:String!=xbTask.str_savePath
        let urlStr:String!=xbTask.str_urlStr
        
        if FileManager.default.fileExists(atPath: savePath) == true //已经存在，表示已经下载完成
        {
            if xbTask.bl_completeBlock != nil
            {
                DispatchQueue.main.async(execute: {
                    weak var weakTask=xbTask
                    xbTask.bl_completeBlock!(weakTask!)
                })
            }
        }
        else if FileManager.default.fileExists(atPath: xbTask.str_savePath_temp) == true //之前有下载，但是没有下载完成
        {
            if xbTask.b_isPause == true
            {
                let data:Data = NSKeyedUnarchiver.unarchiveObject(withFile: xbTask.str_savePath_temp) as! Data
                let downloadTask = XBNetHandle.shared.session.downloadTask(withResumeData: data)
                downloadTask.resume()
                xbTask.setValue(false, forKey: "_isPause")
                xbTask.downloadTask = downloadTask
            }
        }
        else //全新的下载
        {
            if xbTask.b_isPause == true
            {
                let downloadTask = XBNetHandle.shared.session.downloadTask(with: URL(string: urlStr)!)
                downloadTask.resume()
                xbTask.setValue(false, forKey: "_isPause")
                xbTask.downloadTask = downloadTask
            }
        }
    }
    
    class func stop(xbTask:XBDownloadTask) -> Void {
        xbTask.setValue(true, forKey: "_isPause")
        if xbTask.downloadTask != nil
        {
            xbTask.downloadTask!.cancel(byProducingResumeData: { (data:Data?)->Void in
                if data != nil
                {
                    NSKeyedArchiver.archiveRootObject(data!, toFile: xbTask.str_savePath_temp)
                }
            })
        }
    }
}

// MARK: - URLSession代理方法
extension XBNetHandle: URLSessionDownloadDelegate
{
    /// 下载完成
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        let completeObj = XBDownloadCompleteObj()
        completeObj.downloadTask=downloadTask
        completeObj.location=location
        NotificationCenter.default.post(name: NSNotification.Name(rawValue:kNotice_complete), object: completeObj)
    }
    
    /// 下载进度
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        let progressObj = XBDownloadProgressObj()
        progressObj.downloadTask=downloadTask
        progressObj.int_bytesWritten=bytesWritten
        progressObj.int_totalBytesWritten=totalBytesWritten
        progressObj.int_totalBytesExpectedToWrite=totalBytesExpectedToWrite
        NotificationCenter.default.post(name: NSNotification.Name(rawValue:kNotice_progress), object: progressObj)
    }
    
    /// 任务完成、出现错误、手动取消都会跑这个方法
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        if error != nil
        {
            let nserror = error as! NSError
            if nserror.code == 999 //手动取消
            {
                
            }
            else
            {
                let failureObj = XBDownloadFailureObj()
                failureObj.downloadTask=task as! URLSessionDownloadTask
                failureObj.error=error
                NotificationCenter.default.post(name: NSNotification.Name(rawValue:kNotice_failure), object: failureObj)
            }
        }
    }
}

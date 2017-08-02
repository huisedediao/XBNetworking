//
//  XBNetworkingPublic.swift
//  XBHttpHandle
//
//  Created by xxb on 2017/1/7.
//  Copyright © 2017年 xxb. All rights reserved.
//

import Foundation

typealias XBDownloadBlock = ((_ xbTask:XBDownloadTask) -> Void)

typealias XBProgressBlock = XBDownloadBlock
typealias XBCompleteBlock = XBDownloadBlock
typealias XBFailureBlock = ((_ error:Error) -> Void)



let kNotice_progress = "Notice_progress"
let kNotice_complete = "Notice_complete"
let kNotice_failure = "Notice_failure"
let kNotice_downloadTasklistChanged = "Notice_downloadTasklistChanged"



class XBDownloadCompleteObj:NSObject{
    var downloadTask: URLSessionDownloadTask?
    var location: URL?
}
class XBDownloadFailureObj:NSObject{
    var downloadTask: URLSessionDownloadTask!
    var error:Error?
}
class XBDownloadProgressObj:NSObject{
    var downloadTask: URLSessionDownloadTask?
    var int_bytesWritten: Int64?
    var int_totalBytesWritten: Int64?
    var int_totalBytesExpectedToWrite: Int64?
}

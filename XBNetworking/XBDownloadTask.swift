//
//  XBDownloadTask.swift
//  XBHttpHandle
//
//  Created by xxb on 2017/1/7.
//  Copyright © 2017年 xxb. All rights reserved.
//

import UIKit

class XBDownloadTask: NSObject,NSCoding {
    
    /// 下载地址
    var str_urlStr:String?
    
    /// 保存路径(只需传沙盒之后的路径)
    private var _savePath:String?
    var str_savePath:String?{
        set{
            _savePath=newValue
            
            //判断存储文件的文件夹是否存在，不存在则创建
            let lastcomponent = URL(fileURLWithPath: newValue!).lastPathComponent
            let index=newValue?.index((newValue?.endIndex)!, offsetBy: -(lastcomponent.characters.count))
            let savePathWithoutLastComponent = newValue?.substring(to: index!)
            
            if FileManager.default.fileExists(atPath: savePathWithoutLastComponent!) == false
            {
                do
                {
                    try FileManager.default.createDirectory(atPath: savePathWithoutLastComponent!, withIntermediateDirectories: true, attributes: nil)
                }catch{}
            }
        }
        get{
            return NSHomeDirectory() + _savePath!
        }
    }
    
    /// 缓存路径
    var str_savePath_temp:String{ return str_savePath! + "XBDownloadTemp" }
    
    /// 名称
    var str_fileName:String{
        let result=URL(fileURLWithPath: str_savePath!).lastPathComponent
        return result
    }

    /// URLSession的下载任务
    var downloadTask:URLSessionDownloadTask?
    
    /// 进度
    var f_progress:Double{
        if int_totalBytesExpectedToWrite != 0
        {
            return Double(int_totalBytesWritten) / Double(int_totalBytesExpectedToWrite)
        }
        else
        {
            return 0
        }
    }
    
    /// 已写入的大小（转换成KB,MB,GB）
    var str_totalWritten:String{ return getSizeDescribe(bytes: int_totalBytesWritten) }
    
    /// 总的大小（转换成KB,MB,GB）
    var str_totalExpectedToWrite:String{ return getSizeDescribe(bytes: int_totalBytesExpectedToWrite) }

    /// 是否完成
    var _isCompleted = false
    var b_isCompleted:Bool { return _isCompleted }
    
    /// 是否暂停
    var _isPause = true
    var b_isPause:Bool { return _isPause }
    
    
    /// 进度回调
    var bl_progressBlock:XBProgressBlock?
    
    /// 完成回调
    var bl_completeBlock:XBCompleteBlock?
    
    /// 错误回调
    var bl_failureBlock:XBFailureBlock?
    
    /// 本次写入的量
    var int_bytesWritten: Int64 = 0
    
    /// 已经下载的量
    var int_totalBytesWritten: Int64 = 0
    
    /// 总共要下载的量
    var int_totalBytesExpectedToWrite: Int64 = 0
    
    
    override init(){
        _isPause = true
        super.init()
    }
    
    private let key_str_urlStr = "str_urlStr"
    private let key_savePath = "_savePath"
    private let key_b_isCompleted = "b_isCompleted"
    private let key_int_totalBytesWritten = "int_totalBytesWritten"
    private let key_int_totalBytesExpectedToWrite = "int_totalBytesExpectedToWrite"
    
    required init?(coder aDecoder: NSCoder){
        
        str_urlStr=aDecoder.decodeObject(forKey: key_str_urlStr) as! String?
        _savePath=aDecoder.decodeObject(forKey: key_savePath) as! String?
        _isCompleted=aDecoder.decodeBool(forKey: key_b_isCompleted)
        int_totalBytesWritten=aDecoder.decodeInt64(forKey: key_int_totalBytesWritten)
        int_totalBytesExpectedToWrite=aDecoder.decodeInt64(forKey: key_int_totalBytesExpectedToWrite)
        _isPause = true
        super.init()
    }
    
    func encode(with aCoder: NSCoder){
        
        aCoder.encode(str_urlStr, forKey: key_str_urlStr)
        aCoder.encode(_savePath, forKey: key_savePath)
        aCoder.encode(_isCompleted, forKey: key_b_isCompleted)
        aCoder.encode(int_totalBytesWritten, forKey: key_int_totalBytesWritten)
        aCoder.encode(int_totalBytesExpectedToWrite, forKey: key_int_totalBytesExpectedToWrite)
    }
    
    private func getSizeDescribe(bytes:Int64) -> String {
        
        var result:String?
        
        //先判断有没有到KB
        var size:Double=Double(bytes) * 1.0 / 1024;
        if (size<1)
        {
            result="\(int_totalBytesWritten)b"
        }
        else
        {
            size=size / 1024;
            //判断有没有到MB
            if (size<1)
            {
                result=String(format:"%.2f",size * 1024) + "KB"
            }
            else
            {
                //判断有没有到G
                size=size / 1024;
                if (size<1)
                {
                    result=String(format:"%.2f",size * 1024) + "MB"
                }
                else
                {
                    result=String(format:"%.2f",size) + "GB"
                }
            }
        }
        
        return result!
    }
}


//
//  XBDownloadManager.swift
//  XBHttpHandle
//
//  Created by xxb on 2017/1/7.
//  Copyright © 2017年 xxb. All rights reserved.
//

import UIKit

class XBDownloadManager: NSObject {
    
    static let shared=XBDownloadManager()
    private override init() {
        super.init()
        addNotice()
    }
    deinit {
        removeNotice()
    }
    
    fileprivate let listSavePath = NSHomeDirectory() + "/Documents/XBDownloadManager_taskList"
    
    lazy var taskList:[XBDownloadTask] = {
        
        var list:[XBDownloadTask]!
        if FileManager.default.fileExists(atPath: self.listSavePath)
        {
            list=NSKeyedUnarchiver.unarchiveObject(withFile: self.listSavePath) as! [XBDownloadTask]!
        }
        else
        {
            list=[XBDownloadTask]()
        }
        return list
    }()
    
    var unCompletedTaskList:[XBDownloadTask]? {
        
        return taskList.filter { (task) -> Bool in
            task.b_isCompleted == false
        }
    }
    
    var completedTaskList:[XBDownloadTask]? {
        
        return taskList.filter({ (task) -> Bool in
            task.b_isCompleted
        })
    }
}

// MARK: - 任务管理
extension XBDownloadManager{
    
    func addTask(_ xbTask:XBDownloadTask) -> Void {
        
        taskList.append(xbTask)
        saveTaskList()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue:kNotice_downloadTasklistChanged), object: nil)
    }
    
    func removeTask(_ xbTask:XBDownloadTask, deleteFile:Bool) -> Void {
        if xbTask.b_isCompleted
        {
            if deleteFile
            {
                if FileManager.default.fileExists(atPath: xbTask.str_savePath!)
                {
                    do
                    {
                        try FileManager.default.removeItem(atPath: xbTask.str_savePath!)
                    }catch{}
                }
            }
        }
        else
        {
            if xbTask.b_isPause == false //正在下载
            {
                XBDownloadManager.shared.pauseTask(xbTask)
            }
            
            if FileManager.default.fileExists(atPath: xbTask.str_savePath_temp)
            {
                do
                {
                    try FileManager.default.removeItem(atPath: xbTask.str_savePath_temp)
                }catch{}
            }
        }

        taskList.remove(at: taskList.index(of: xbTask)!)
        saveTaskList()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue:kNotice_downloadTasklistChanged), object: nil)
    }
    
    func saveTaskList() -> Void {
        
        NSKeyedArchiver.archiveRootObject(taskList, toFile: listSavePath)
    }
    
    func startTask(_ xbTask:XBDownloadTask, progressBlock: XBProgressBlock?, completeBlock: XBCompleteBlock?, failureBlock: XBFailureBlock?) -> Void {
        
        if progressBlock != nil{ xbTask.bl_progressBlock=progressBlock }
        if completeBlock != nil{ xbTask.bl_completeBlock=completeBlock }
        if failureBlock  != nil{ xbTask.bl_failureBlock=failureBlock }
        
        var tempTask:XBDownloadTask?
        //先判断列表中有没有该任务（相同任务或者相同的下载链接并且相同的存储位置视作同一任务）
        for task in taskList
        {
            if task == xbTask
            {
                tempTask = task
                break
            }
        }
        
        if tempTask == nil // 如果列表中没有该任务，判断下载地址和存储路径是否同时和任务列表中的某个任务相同
        {
            for task in taskList
            {
                if task.str_urlStr == xbTask.str_urlStr && task.str_savePath == xbTask.str_savePath
                {
                    tempTask = task
                    break
                }
            }
        }
        
        if tempTask != nil  //任务已存在
        {
            if (tempTask?.b_isCompleted)!  //任务已经完成
            {
                if xbTask.bl_completeBlock != nil
                {
                    DispatchQueue.main.async(execute: {
                        weak var weakTask=xbTask
                        xbTask.bl_completeBlock!(weakTask!)
                    })
                }
            }
            else if (tempTask?.b_isPause)!  //任务未完成，并处于暂停（停止）状态
            {
                XBNetHandle.downFileWith(xbTask: tempTask!)
            }
            else //任务未完成，并处于下载状态
            {
                XBNetHandle.downFileWith(xbTask: tempTask!)
            }
        }
        else //任务不存在
        {
            var savePathExist:Bool=false
            
            //不存在，遍历数组，查看保存路径是否已经被占用
            for item in taskList
            {
                if item.str_savePath == xbTask.str_savePath
                {
                    savePathExist=true
                    break
                }
            }
            
            if savePathExist
            {
                let savePathUrl=URL(fileURLWithPath: xbTask.str_savePath!)
                //弹窗提醒，名字重复，请重新命名
                let alertController=UIAlertController(title: "名称已存在！", message: "\(savePathUrl.lastPathComponent) 名称已存在，请重命名", preferredStyle: UIAlertControllerStyle.alert)
                let action = UIAlertAction(title: "ok", style: UIAlertActionStyle.default, handler: nil)
                alertController.addAction(action)
                let dele = UIApplication.shared.delegate
                let rootVC = (dele?.window)!?.rootViewController
                rootVC?.present(alertController, animated: true, completion: nil)
            }
            else//都不存在，添加任务到列表，开始任务
            {
                addTask(xbTask)
                XBNetHandle.downFileWith(xbTask: xbTask)
            }
        }
    }
    
    func pauseTask(_ xbTask:XBDownloadTask) -> Void {
        
        XBNetHandle.stop(xbTask: xbTask)
    }
    
    func pauseAllTask() -> Void {
        
        if unCompletedTaskList == nil
        {
            return
        }
        
        for task in unCompletedTaskList!
        {
            if task.b_isPause == false
            {
                pauseTask(task)
            }
        }
    }
    
    func exitHandle() -> Void {
        
        pauseAllTask()
        saveTaskList()
    }
}

// MARK: - 处理下载回调
extension XBDownloadManager{
    
    func addNotice () -> Void {
        NotificationCenter.default.addObserver(self, selector: #selector(self.taskProgressHandle(noti:)), name: NSNotification.Name(rawValue:kNotice_progress), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.taskCompleteHandle(noti:)), name: NSNotification.Name(rawValue:kNotice_complete), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.taskFailureHandle(noti:)), name: NSNotification.Name(rawValue:kNotice_failure), object: nil)
    }
    
    func removeNotice () -> Void {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue:kNotice_progress), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue:kNotice_complete), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue:kNotice_failure), object: nil)
    }
    
    func taskProgressHandle(noti:NSNotification) -> Void {
        print("这是任务进度的回调")
        let progressObj=noti.object as! XBDownloadProgressObj
        let resultArr = taskList.filter { (task) -> Bool in
            task.downloadTask==progressObj.downloadTask
        }
        let task = resultArr[0]
        task.int_bytesWritten=progressObj.int_bytesWritten!
        task.int_totalBytesWritten=progressObj.int_totalBytesWritten!
        task.int_totalBytesExpectedToWrite=progressObj.int_totalBytesExpectedToWrite!
        
        if task.bl_progressBlock != nil
        {
            DispatchQueue.main.async(execute: {
                weak var weakTask=task
                task.bl_progressBlock!(weakTask!)
            })
        }
    }
    
    func taskCompleteHandle(noti:NSNotification) -> Void {
        print("这是任务完成的回调")
        let completeObj=noti.object as! XBDownloadCompleteObj
        let resultArr = taskList.filter { (task) -> Bool in
            task.downloadTask==completeObj.downloadTask
        }
        let task = resultArr[0]
        task.setValue(true, forKey: "_isPause")
        task.setValue(true, forKey: "_isCompleted")
        saveTaskList()
        
        do
        {
            //移动下载完成的任务到指定路径
            try FileManager.default.moveItem(at: completeObj.location!, to: URL.init(fileURLWithPath: task.str_savePath!))
            
            //删除缓存
            if FileManager.default.fileExists(atPath: task.str_savePath_temp)
            {
                do
                {
                    try FileManager.default.removeItem(atPath: task.str_savePath_temp)
                } catch {}
            }
        } catch{}
        
        if task.bl_completeBlock != nil
        {
            DispatchQueue.main.async(execute: {
                weak var weakTask=task
                task.bl_completeBlock!(weakTask!)
            })
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue:kNotice_downloadTasklistChanged), object: nil)
    }
    
    func taskFailureHandle(noti:NSNotification) -> Void {
        let failureObj=noti.object as! XBDownloadFailureObj
        let resultArr = taskList.filter { (task) -> Bool in
            task.downloadTask==failureObj.downloadTask
        }
        let task = resultArr[0]
        task.setValue(true, forKey: "_isPause")
        
        if task.bl_failureBlock != nil
        {
            DispatchQueue.main.async(execute: { 
                task.bl_failureBlock!(failureObj.error!)
            })
        }
    }
}

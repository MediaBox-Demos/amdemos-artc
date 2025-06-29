[English](README_English.md)

# ARTC SDK API Example iOS (Swift)
阿里云 · ARTC SDK Demo

## 介绍
ARTC SDK iOS平台(Swift语言)的API示例Demo，展示ARTC SDK 的API调用示例，核心场景的接口调用参考

## 源码说明

### 源码下载
下载地址[请参见](https://github.com/MediaBox-Demos/amdemos-artc/tree/main/iOS)

### 源码结构
```
├── iOS                                // iOS平台工程结构根目录
│   ├── ARTCExample                    // API Example源码目录
│       ├── Common                     // 通用模块
│           ├── ARTCTokenHelper.swift      // 设置AppId/AppKey等信息
│           ├── ...                        // 其他文件
│       ├── QuickStart                 // 快速开发模块
│           ├── TokenGenerate              // Token生成及入会
│           ├── VideoCall                  // 快速实现音视频通话
│           ├── VoiceChat                  // 快速实现语聊房
│       ├── Setting                    // 设置模块
│       ├── ...                        // 工程其他文件
│   ├── ARTCExample.xcodeproj          // Demo的Project
│   ├── ARTCExample.xcworkspace        // Demo的workspace
│   ├── Podfile                        // Demo的podfile文件

```

### 环境要求
- Xcode 16 及以上版本，推荐使用最新正式版本
- CocoaPods 1.9.3 及以上版本
- 准备 iOS 10.0 及以上版本的真机

### 前提条件
到阿里云视频直播控制台左侧导航栏，选择直播+ > 实时音视频 > 应用管理，在应用管理页面，单击创建应用，申请AppID，AppKey等信息。


## 跑通ARTC API Example源码


- 源码下载后，打开iOS目录
- 在iOS目录里执行命令“pod install  --repo-update”，自动安装依赖SDK
- 打开工程文件`ARTCExample.xcworkspace`
- 配置实时音视频AppID和AppKey
进入`iOS/ARTCExample/Common/ARTCTokenHelper.swift`将控制台申请的AppID和AppKey填入
```swift
// ARTCTokenHelper.swift


class ARTCTokenHelper: NSObject {
    
    /**
     * RTC AppId
     */
    public static let AppId = "<实时音视频AppID>"
    
    /**
     * RTC AppKey
     */
    public static let AppKey = "<实时音视频AppKey>"
    
    ...
}
```
- 选择”ARTCExample“Target, 连接真机，进行编译
- 运行App，即可体验API Example


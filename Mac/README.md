[English](README_English.md)

# ARTC SDK API Example Mac (ObjectC++)
阿里云 · ARTC SDK Demo

## 介绍
ARTC SDK Mac平台(Object C++语言)的API示例Demo，展示ARTC SDK 的API调用示例，核心场景的接口调用参考

## 源码说明

### 源码下载
下载地址[请参见](https://github.com/MediaBox-Demos/amdemos-artc/tree/main/Mac)

### 源码结构
```
├── Mac                         // Mac平台工程结构根目录
│   ├── ARTCExample                // API Example源码目录
│       ├── Common                      // 通用模块
│       ├── QuickStart                  // 快速开发模块
│           ├── TokenGenerate           // Token生成及入会
│           ├── VideoCall               // 快速实现音视频通话
│           ├── VoiceChat               // 快速实现语聊房
│       ├── BasicUsage                  // 基础功能模块
│           ├── ScreenShare             // 屏幕共享
│       ├── ...                         // 工程其他文件
│   ├── ARTCExample.xcodeproj        // Demo的Project

```

### 环境要求
- Xcode 16 及以上版本，推荐使用最新正式版本
- 准备 Mac 14 及以上版本的真机

### 前提条件
到阿里云视频直播控制台左侧导航栏，选择直播+ > 实时音视频 > 应用管理，在应用管理页面，单击创建应用，申请AppID，AppKey等信息。


## 跑通ARTC API Example源码


- 源码下载后，打开Mac目录
- 打开工程文件`ARTCExample.xcodeproj`
- 配置Common/AppDefine.h文件中的实时音视频AppID和AppKey
进入`Mac/ARTCExample/Common/AppDefine.h`将控制台申请的AppID和AppKey填入
```

#define ARTC_APP_ID  "<实时音视频AppID>"
#define ARTC_APP_KEY "<实时音视频AppKey>"

```
- 配置项目签名信息，进入项目配置界面，选择Signing & Capabilities，勾选Automatically manage signing
- 运行App，即可体验API Example
